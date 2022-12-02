require_relative 'setup_verification_service'

module VerificationService
  class << self
    def handler(event:, context:) # rubocop:disable Lint/UnusedMethodArgument
      Log.info('VerificationService: start verification')
      data = event.dig('detail', 'data')
      action, job_id, timestamp = data.values_at('action', 'job_id', 'timestamp')
      application = Models::Application.factory(data['application_id'], data['partner_id'], event)

      case action
      when 'income-calc'
        result = calculate_income(application)
        process_response(application, result, 'income_calculations', job_id, timestamp)
      when 'verify'
        result = run_f3(application)
        process_response(application, result, 'stip_verifications', job_id, timestamp)
      end
    rescue LambdaFunctions::PartnerProfile::Non200Error
      Log.error("VerificationService:ERROR #{data}")
    end

    def process_response(application, payload, action, job_id, timestamp)
      Log.info('VerificationService: processing response')
      cls = ConstantizeHelper.constantize("Serializers::#{action.camelize}::Response")
      serialized_response = cls.serialize(application, payload, job_id, timestamp)

      app_id = application.id
      partner_id = application.partner_id

      uri = AwsS3.stipulation_service_results(app_id, partner_id, action).uri_for("#{app_id}.json")
      serialized_response = JSON.dump(serialized_response)

      s3_response = AwsS3.stipulation_service_results(app_id, partner_id, action).direct_upload_from_content(
        serialized_response, "#{app_id}.json"
      )
      uri += "##{s3_response.version_id}"

      event_payload = send("#{action}_payload", app_id, partner_id, uri, job_id)
      Log.debug("VerifiactionService: event payload #{event_payload}")

      EventBridge.put_event(event_payload, EventBridge::VERIFICATION_PROCESS_COMPLETE)
    end

    def calculate_income(application)
      Log.info('VerificationService: calculating income')
      return unless application.present?

      application.applicants.each_with_object({}) do |applicant, result|
        payload = {
          application: application,
          applicant:   applicant
        }
        result[applicant.id.to_sym] = ConsolidatedIncomes::ConsolidatedIncomeWrapper.calculate_income(
          :income_api, :income_api, payload
        )
      end
    end

    def run_f3(application)
      Log.info('VerificationService: running f3')
      return unless application.present?
      engine = ApplicationFundingEngine::LenderRuleEngine.factory(application.partner_id)
      return unless engine.present?

      # Question: skip running stips in pass status?

      engine_results = {}
      doc_ids = []

      # Application level
      if application.stipulations.present?
        facts, document_ids = ApplicationFundingEngine::FactsCalculator.calculate(
          application, application_level: true, available_documents: application.documents
        ).values_at(:facts, :document_ids)
        doc_ids.append(*document_ids) unless document_ids.empty?
        engine_results["application_#{application.id}"] = engine.apply_facts(facts)
      end

      # Applicant level
      application.applicants.each do |applicant|
        facts, document_ids = ApplicationFundingEngine::FactsCalculator.calculate(
          applicant, application: application, available_documents: applicant.documents
        ).values_at(:facts, :document_ids)
        doc_ids.append(*document_ids) unless document_ids.empty?
        engine_results["applicant_#{applicant.id}"] = engine.apply_facts(facts)
      end

      driver_results = []

      # Application level drivers
      application.stipulations.each do |stip|
        next if stip[:waived]
        driver_results << ApplicationFundingEngine::Driver.fire(application, application.applicants.first, stip, engine_results.dig("application_#{application.id}", stip[:type].to_sym), engine, partner_id: application.partner_id) # rubocop:disable Layout/LineLength
      end

      # Applicant level drivers
      application.applicants.each do |applicant|
        applicant.stipulations.each do |stip|
          next if stip[:waived]
          driver_results << ApplicationFundingEngine::Driver.fire(application, applicant, stip, engine_results.dig("applicant_#{applicant.id}", stip[:type].to_sym), engine, partner_id: application.partner_id) # rubocop:disable Layout/LineLength
        end
      end

      driver_results.group_by { |result| result[:stip_type] }
    end

    def income_calculations_payload(app_id, partner_id, payload_uri, job_id)
      {
        metadata: {
          traceparent:     '',
          event_date_time: Time.now.to_s,
          domain:          'lambda'
        },
        data:     {
          application_id:         app_id,
          partner_id:             partner_id,
          job_id:                 job_id,
          jwt:                    '',
          action:                 'income-calc',
          income_calculation_uri: payload_uri
        }
      }
    end

    def stip_verifications_payload(app_id, partner_id, payload_uri, job_id)
      {
        metadata: {
          traceparent:     '',
          event_date_time: Time.now.to_s,
          domain:          'lambda'
        },
        data:     {
          application_id:         app_id,
          partner_id:             partner_id,
          job_id:                 job_id,
          jwt:                    '',
          action:                 'verify',
          stipulation_result_uri: payload_uri
        }
      }
    end
  end
end
