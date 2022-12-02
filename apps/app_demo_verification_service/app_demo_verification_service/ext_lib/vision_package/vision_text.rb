require_relative 'vision_text_helper'

module VisionPackage
  class VisionText
    include VisionTextHelper

    attr_reader :text

    delegate :length, :match?, to: :text
    delegate_missing_to :text

    class << self
      def factory(text)
        text.is_a?(VisionText) ? text : VisionPackage::VisionText.new(text)
      end

      def dollar_amount(text, options = {})
        skip_regex = options.fetch(:skip_regex, true)

        factory(text).dollar_amount(skip_regex: skip_regex)
      end

      def to_date(text, options = {})
        skip_regex = options.fetch(:skip_regex, true)

        text.respond_to?(:strftime) ? text : factory(text).to_date(skip_regex: skip_regex)
      end

      def to_hours(text, options = {})
        skip_regex = options.fetch(:skip_regex, true)

        factory(text).to_hours(skip_regex: skip_regex)
      end

      def to_hourly_rate(text, options = {})
        skip_regex = options.fetch(:skip_regex, true)

        factory(text).to_hourly_rate(skip_regex: skip_regex)
      end

      def to_ssn(text, options = {})
        skip_regex = options.fetch(:skip_regex, true)

        factory(text).to_ssn(skip_regex: skip_regex)
      end

      def to_vin(text, options = {})
        skip_regex = options.fetch(:skip_regex, true)

        factory(text).to_vin(skip_regex: skip_regex)
      end

      def to_odometer(text, options = {})
        min = options.fetch(:min, nil)

        factory(text).to_odometer(min: min)
      end
    end

    def initialize(text)
      @text = text.to_s
    end

    def dollar?(options = {})
      strict = options.fetch(:strict, false)

      match?(strict ? RegexConstants::CURRENCY_WORD_CLEAN : RegexConstants::CURRENCY_WORD)
    end

    def dollar_amount(options = {})
      skip_regex = options.fetch(:skip_regex, false)

      text_to_dollar_amount(text) if skip_regex || dollar?
    end

    def date?
      match?(RegexConstants::ALL_DATE) && !dollar?
    end

    def partial_date?
      match?(RegexConstants::PARTIAL_DATE_WORD) && !match?(RegexConstants::ALL_DATE)
    end

    def to_date(options = {})
      skip_regex = options.fetch(:skip_regex, false)

      text_to_date(text) if skip_regex || date?
    end

    def to_full_date(compare_date)
      to_date || partial_text_to_date(text, compare_date)
    end

    def hours?(options = {})
      strict = options.fetch(:strict, false)

      match?(strict ? RegexConstants::HRS_AMOUNTS : RegexConstants::HRS_LOOSE)
    end

    def to_hours(options = {})
      skip_regex = options.fetch(:skip_regex, false)

      text_to_hours(text) if skip_regex || hours?
    end

    def hourly_rate?
      match?(RegexConstants::HRS_RATE)
    end

    def to_hourly_rate(options = {})
      skip_regex = options.fetch(:skip_regex, false)

      dollar_amount(skip_regex: skip_regex) || text_to_hourly_rate(text) if skip_regex || hourly_rate?
    end

    def ssn?
      match?(RegexConstants::SSN)
    end

    def to_ssn(options = {})
      skip_regex = options.fetch(:skip_regex, false)

      text_to_ssn(text) if skip_regex || ssn?
    end

    def vin?
      match?(RegexConstants::VIN_NUMBER) || match?(RegexConstants::LOOSE_VIN_NUMBER)
    end

    def to_vin(options = {})
      skip_regex = options.fetch(:skip_regex, false)

      text_to_vin(text) if skip_regex || vin?
    end

    def percent?
      match?(RegexConstants::PERCENT)
    end

    def to_percent
      text_to_percent(text) if percent?
    end

    def odometer?(options = {})
      min = options.fetch(:min, nil)

      return false unless match?(RegexConstants::ODOMETER_WORD) && text.size <= 8 && !dollar?
      text_to_odometer(text).to_i.between?(min || 1_000, 350_000)
    end

    def to_odometer(options = {})
      min = options.fetch(:min, nil)

      text_to_odometer(text) if odometer?(min: min)
    end

    def to_int
      text_to_int(text)
    end

    def formattable?(options = {})
      strict = options.fetch(:strict, true)

      date? || dollar? || partial_date? || hourly_rate? || hours?(strict: strict) || vin? || percent? || odometer?
    end

    def formatted_text
      return text if partial_date?
      return to_date if date?
      return dollar_amount if dollar?
      return to_hourly_rate if hourly_rate?
      return to_hours if hours?
      return to_vin if vin?
      return to_odometer if odometer?
      return to_ssn if ssn?
      to_percent if percent?
    end

    def valuable?(options = {})
      strict = options.fetch(:strict, false)

      dollar? || hours?(strict: strict) || hourly_rate?
    end

    def to_s
      text
    end

    def eql?(other)
      other.is_a?(VisionPackage::VisionText) && to_s == other.to_s
    end

    alias == eql?

    alias inspect to_s
  end
end
