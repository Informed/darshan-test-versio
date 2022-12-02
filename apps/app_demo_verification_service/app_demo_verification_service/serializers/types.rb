module Serializers::Types
  include Dry.Types()
  SymbolizeAndOptionalSchema ||= Hash.schema({}).
                                 with_key_transform(&:to_sym).
                                 with_type_transform(&:omittable)

  OmittableString ||= Nominal::String.optional.meta(omittable: true)
  OmittableFloat ||= Nominal::Float.optional.meta(omittable: true)
  OmittableInt ||= Nominal::Integer.optional.meta(omittable: true)

  Address ||= SymbolizeAndOptionalSchema.schema(street_address: OmittableString,
                                                street2:        OmittableString,
                                                city:           OmittableString,
                                                state:          OmittableString,
                                                zip:            OmittableString).optional.meta(omittable: true)
end
