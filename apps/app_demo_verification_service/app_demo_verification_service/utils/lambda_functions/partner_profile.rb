module LambdaFunctions
  class PartnerProfile < AwsLambda
    class Non200Error < StandardError; end

    attr_reader :partner_uuid

    CAPITALONE ||= 'capitalone'.freeze
    WESTLAKE ||= 'westlake'.freeze
    ACMEFINANCIAL ||= 'acmefinancial'.freeze

    class << self
      def get(partner_uuid, namespace)
        Log.info("VerificationService: get PartnerProfile - #{partner_uuid} - #{namespace}")
        result = PartnerProfileCache.from_cache(partner_uuid.to_s, namespace)
        return result if result.present?

        result = new(partner_uuid).process
        raise Non200Error unless result.present?
        Log.info("VerificationService: caching PartnerProfile - #{partner_uuid}")
        PartnerProfileCache.to_cache(partner_uuid.to_s, result)
        PartnerProfileCache.from_cache(partner_uuid.to_s, namespace)
      end
    end

    def initialize(partner_uuid)
      super('partner-profile')
      @partner_uuid = partner_uuid
    end

    def process
      Log.info("VerificationService: invoking PartnerProfile #{partner_uuid}")
      payload = {
        'rawPath':        "/v1/partner_profiles/#{partner_uuid}",
        'headers':        {
          'traceparent': ''
        },
        'requestContext': {
          'http':  { 'method': 'GET' },
          'stage': '$default'
        }
      }

      response = JSON.parse(execute(payload).payload.read)['body']
      JSON.parse(response)
    end
  end
end
