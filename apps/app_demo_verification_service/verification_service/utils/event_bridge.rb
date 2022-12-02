class EventBridge
  using Refinements::HashTransformations
  # VerificationService -> ApplicationOrchestrator
  VERIFICATION_PROCESS_COMPLETE ||= {
    detail_type: 'VerificationProcessComplete',
    source:      'verificationService'
  }.freeze

  EVENT_BUS_NAME ||= "techno-core-#{ENV.fetch('Environment', 'dev')}".freeze
  DEVELOPMENT ||= 'development'.freeze

  def self.client
    return @@client if defined?(@@client)
    @@client ||= Aws::EventBridge::Client.new
  end

  def self.event_payload(event_type, payload)
    payload = payload.is_a?(String) ? payload : JSON.dump(payload)
    {
      entries: [
        {
          time:           Time.now,
          source:         event_type[:source],
          detail_type:    event_type[:detail_type],
          detail:         payload,
          event_bus_name: EVENT_BUS_NAME
        }
      ]
    }
  end

  def self.put_event(payload, event_type)
    Log.info("VerificationService: put event #{event_type}")
    EventBridge.client.put_events(event_payload(event_type, payload))
  end

  def self.data_parser(payload, uri_key = 'messageDataUri')
    uri_data = payload.dig('detail', 'data', uri_key.to_s)
    return unless uri_data.present?
    return data_parser_helper(uri_data) if uri_data.is_a?(String)
    return uri_data.map { |uri_datum| data_parser_helper(uri_datum) } if uri_data.is_a?(Array)
    raise "Unsupported data type: #{uri_data.class.name}"
  end

  def self.data_parser_helper(full_uri)
    full_uri = full_uri['document_uri'] if full_uri.is_a?(Hash)
    uri, version = full_uri.split('#')
    uri = URI.parse(uri)
    protocol = uri.scheme
    content = case protocol
              when 's3'
                EventBridge.s3_handler(uri, version)
              else
                raise "Unsupported data protocol: #{protocol}"
              end
    JSON.parse(content).underscore_keys
  end

  def self.s3_handler(uri, version)
    AwsS3.file_content(uri, version)
  end
end
