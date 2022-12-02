class AnalysisDocumentSerializer
  DATE_FIELDS ||= %i[issue_date bill_due_date bill_issue_date dob expired hire_date current_date pay_date pay_end_date
                     pay_begin_date invoice_date first_working_day contract_date effective_date expiration_date
                     first_payment_date paystub_date_loose paystub_date_issue eff_date exp_date statement_date
                     statement_begin_date statement_end_date].freeze
  class ::AnalysisDocumentDummy
    attr_reader :id, :document_reference_id, :input_source, :document_type, :stip_type, :payload, :file_name,
                :application_id, :applicant_id, :is_digital, :file_ids, :file_reference_ids, :belongs_to

    def initialize(id, document_reference_id, input_source, document_type, stip_type, payload, file_name, app_id,
                   applicant_id, is_digital, file_ids, file_reference_ids, belongs_to)
      @id = id
      @document_reference_id = document_reference_id
      @input_source = input_source
      @document_type = document_type
      @stip_type = stip_type
      @payload = payload
      @file_name = file_name
      @application_id = app_id
      @applicant_id = applicant_id
      @is_digital = is_digital
      @file_ids = file_ids || []
      @file_reference_ids = file_reference_ids || []
      @belongs_to = belongs_to || []
    end

    def applicant_full_address(applicant_id)
      address&.dig(applicant_id&.to_sym, :full_address) if respond_to?(:address)
    end

    def applicant_full_name(applicant_id)
      name&.dig(applicant_id&.to_sym, :full_name) if respond_to?(:name)
    end
  end

  def self.from_payload(payload)
    cls = ::AnalysisDocumentDummy.new(*payload.values_at(
      :document_id, :document_reference_id, :input_source, :document_type, :stip_type, :analysis_document_payload,
      :serialized_file_name, :application_id, :applicant_id, :is_digital, :file_ids, :file_reference_ids, :belongs_to
    ))
    payload[:analysis_document_payload]&.each do |method, val|
      # rubocop:disable Style/DocumentDynamicEvalDefinition
      if val.is_a?(String) && val.match?(/\Adef.*end\z/im)
        cls.instance_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          #{val}
        RUBY
      else
        val = val.is_a?(String) && DATE_FIELDS.include?(method) ? "VisionPackage::VisionText.to_date('#{val}')" : val
        val = val.is_a?(String) && !val.start_with?('Vision') ? "'#{val}'" : val
        val = 'nil' if val.nil?
        val = method == :id ? "'#{cls.id}'" : val
        cls.instance_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{method}
            #{val}
          end
        RUBY
      end
      # rubocop:enable Style/DocumentDynamicEvalDefinition
    end
    cls
  end
end
