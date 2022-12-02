module Serializers
  module IncomeCalculations
    class Response
      using Refinements::HashTransformations

      def self.serialize(application, payload, job_id, timestamp)
        new(application, payload, job_id, timestamp).serialize
      end

      attr_reader :application, :payload

      def initialize(application, payload, job_id, timestamp)
        @application = application
        @payload = payload
        @job_id = job_id
        @timestamp = timestamp
      end

      def serialize
        Serializers::IncomeCalculations::Struct.new(preprocess).to_hash.underscore_keys
      end

      private

      def preprocess
        { calculated_incomes: preprocess_incomes }
      end

      def preprocess_incomes
        # I am assuming there is only one applicant for this flow
        # Other applicant info will be unused
        group_incomes_by_year(payload[:applicant1]).map do |year, results|
          income_sources = preprocess_income_sources(results)
          next unless income_sources.present?
          {
            year:           year,
            income_sources: income_sources
          }
        end.compact
      end

      def group_incomes_by_year(incomes)
        incomes.each_with_object({}) do |(source, values), result|
          values.each do |val|
            val_with_source = { source: source }.merge(val)
            result.key?(val[:year]) ? result[val].append(val_with_source) : result[val[:year]] = [val_with_source]
          end
        end
      end

      def preprocess_income_sources(results)
        results.map do |res|
          next unless res[:income]
          {
            source_type:              res[:source].to_s,
            calculated_income_amount: res[:income],
            document_resource_ids:    res[:most_relevant_documents]&.map { |d| d[:document_id] }
          }
        end.compact
      end
    end
  end
end
