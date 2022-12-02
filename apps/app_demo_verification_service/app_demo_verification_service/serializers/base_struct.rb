module Serializers
  class BaseStruct < Dry::Struct
    transform_keys(&:to_sym)
  end
end
