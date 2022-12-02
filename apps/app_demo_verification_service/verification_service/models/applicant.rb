module Models
  class Applicant < OpenStruct # rubocop:disable Style/OpenStructUse
    class << self
      def factory(applicant_id, application, payload)
        applicant_data = {
          id:             applicant_id.to_s,
          application_id: application.id
        }.merge(payload)
        clean_employment_type(applicant_data)
        new(applicant_data)
        # applicant.application = application
      end

      def clean_employment_type(applicant_data)
        return unless applicant_data.key?(:employment_info)
        applicant_data[:employment_info].each { |ei| ei[:employment_type] = ei[:employment_type].to_s.underscore }
      end
    end
  end
end
