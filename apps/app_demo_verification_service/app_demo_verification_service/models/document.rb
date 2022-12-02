module Models
  class Document < OpenStruct # rubocop:disable Style/OpenStructUse
    EMPTY ||= ''.freeze

    class << self
      def factory(application_id, applicant_id, payload)
        payload[:application_id] = application_id
        payload[:applicant_id] = applicant_id

        if payload.key?(:analysis_document_payload)
          ::AnalysisDocumentSerializer.from_payload(
            payload.slice(
              :document_id, :document_type, :stip_type, :analysis_document_payload, :is_digital, :file_ids,
              :file_reference_ids, :belongs_to, :application_id, :applicant_id
            )
          )
        else
          payload.merge!(payload.delete(:extracted_data) || {})
          payload.merge!(payload.delete(:supplemental_data) || {})
          payload = payload.deep_transform_values { |v| v == EMPTY ? nil : v }
          JSON.parse(payload.to_json, object_class: self)
        end
      end
    end

    def id
      document_id
    end

    def applicant_full_name(applicant_id)
      applicant = applicants&.send(applicant_id)
      return unless applicant

      [applicant.first_name, applicant.middle_name, applicant.last_name].compact.join(' ')
    end

    def applicant_full_address(applicant_id)
      addr = applicants&.send(applicant_id)&.address
      return unless addr

      street_addr = [addr.street_address, addr.street2, addr.city].compact.join(' ')
      city_state_zip = [addr.state, addr.zip].compact.join(' ')
      addr = "#{street_addr}, #{city_state_zip}"
      GeocodeHelper.geocode(addr).full_address
    end
  end
end
