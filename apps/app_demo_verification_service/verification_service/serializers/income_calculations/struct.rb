module Serializers
  module IncomeCalculations
    class IncomeSource < Serializers::BaseStruct
      attribute :source_type, Serializers::Types::String
      attribute :calculated_income_amount, Serializers::Types::Float
      attribute :document_resource_ids, Serializers::Types::Strict::Array.of(IncomeApi::Types::String)
    end

    class CalculatedIncome < Serializers::BaseStruct
      attribute :year, Serializers::Types::Integer
      attribute :income_sources, Serializers::Types::Strict::Array.of(
        Serializers::IncomeCalculations::IncomeSource
      )
    end

    class Struct < Serializers::BaseStruct
      attribute :calculated_incomes, Serializers::Types::Strict::Array.of(
        Serializers::IncomeCalculations::CalculatedIncome
      ).meta(omittable: true)
    end
  end
end
