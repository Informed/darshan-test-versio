module LenderConfig
  using Refinements::HashTransformations

  class << self
    def from_partner_uuid(partner_uuid, namespace = :stipulation_verification_config)
      return if partner_uuid.blank?
      Log.info('VerificationService: LenderConfig call')
      LambdaFunctions::PartnerProfile.get(partner_uuid, namespace)&.underscore_keys
    rescue LambdaFunctions::PartnerProfile::Non200Error
      raise LambdaFunctions::PartnerProfile::Non200Error
    rescue => e
      Honeybadger.notify(e, context: { partner_uuid: partner_uuid, message: 'Failed to load lender config' })
      nil
    end
  end
end
