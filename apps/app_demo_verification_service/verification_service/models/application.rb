module Models
  class Application < OpenStruct # rubocop:disable Style/OpenStructUse
    class << self
      def factory(application_id, partner_id, payload)
        application_data = {
          id:         application_id.to_s,
          partner_id: partner_id
        }.merge(EventBridge.data_parser(payload, :application_data_uri))
        application = new(application_data)

        application.applicants = application_data[:applicants].sort_by { |k, _| k }.map do |id, data|
          Models::Applicant.factory(id, application, data)
        end

        application = parse_documents(application, payload)
        application = parse_stipulations(application, payload)
        application = parse_auto(application, application_data)
        application.assets = application_data[:assets]
        application
      end

      def parse_documents(application, payload)
        documents = EventBridge.data_parser(payload, :document_uris) || []
        applicants_documents = {}
        documents.each do |doc|
          next unless doc[:belongs_to].present?
          doc[:belongs_to].each do |applicant_id|
            if applicants_documents.key?(applicant_id)
              applicants_documents[applicant_id].append(Models::Document.factory(application.id, applicant_id, doc))
            else
              applicants_documents[applicant_id] = [Models::Document.factory(application.id, applicant_id, doc)]
            end
          end
        end

        application.applicants.each do |applicant|
          applicant.documents = applicants_documents[applicant.id] || []
        end

        application_only_documents = documents.map do |doc|
          Models::Document.factory(application.id, application.applicants.first, doc) if doc[:belongs_to].blank?
        end.compact

        application.documents = applicants_documents.values.flatten + application_only_documents
        application
      end

      def parse_stipulations(application, event_payload)
        payload = EventBridge.data_parser(event_payload, :stipulations_data_uri)
        return application if payload.blank?

        applicants_stipulations = {}
        application_stipulations = []

        payload[:verifications].each do |stip, details|
          details.each do |detail|
            if detail[:belongs_to] == 'application'
              application_stipulations.append(detail.merge(type: stip))
            else
              applicant_id = detail[:belongs_to]
              if applicants_stipulations.key?(applicant_id)
                applicants_stipulations[applicant_id].append(detail.merge(type: stip))
              else
                applicants_stipulations[applicant_id] = [detail.merge(type: stip)]
              end
            end
          end
        end

        application.applicants.each do |applicant|
          applicant.stipulations = applicants_stipulations[applicant.id] || []
        end

        application.stipulations = application_stipulations
        application
      end

      def parse_auto(application, data)
        application.auto = Models::Auto.factory(application, data[:vehicle_info], data[:dealer_info])
        application
      end
    end
  end
end
