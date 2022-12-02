module Models
  class Auto < OpenStruct # rubocop:disable Style/OpenStructUse
    class << self
      def factory(application, auto_info, dealer_info)
        return unless auto_info.present?
        auto_data = {
          id:             SecureRandom.uuid,
          application_id: application.id,
          dealer_info:    dealer_info
        }.merge(auto_info)
        new(auto_data)
        # auto.application = application
      end
    end
  end
end
