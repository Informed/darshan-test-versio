require_relative 'bounds'
require_relative 'vision_text'

module VisionPackage
  class VisionWord
    attr_reader :text, :bounds, :combined_indices, :corrected_text, :vision_text, :vision_corrected_text, :polygons

    attr_accessor :category

    delegate :centroid, :minmax_x, :minmax_y, :min_x, :max_x, :min_y, :max_y, :angle, :rotated?, to: :bounds
    delegate :length, :formattable?, :formatted_text, :valuable?, to: :vision_text
    delegate_missing_to :bounds

    class << self
      def factory(words)
        return if words.nil?
        array = words.is_a?(Array)
        words = [words] unless array
        # TODO: need to add in y_offset for each word
        words = words.map { |word| word.is_a?(VisionWord) ? word : VisionWord.new(word) }
        array ? words : words.first
      end

      def deep_clone(word, options = {})
        text = options.fetch(:text, nil)

        return unless word.is_a?(VisionWord)
        word = text.present? ? word.to_h.merge('text' => text.to_s, 'corrected_text' => text.to_s) : word.to_h
        VisionWord.factory(word)
      end

      def distance_between(word1, word2)
        word1, word2 = factory([word1, word2])
        word1.distance_to(word2)
      end

      def intersection_orientation(word1, word2, tolerance = nil)
        word1, word2 = factory([word1, word2])
        return :vertical if word1.intersects_vertically?(word2, tolerance)
        :horizontal if word1.intersects_horizontally?(word2, tolerance)
      end

      def intersection_percent(word1, word2, axis)
        word1, word2 = factory([word1, word2])
        word1.send("#{axis}_intersection_percent", word2)
      end

      def intersects?(word1, word2, hor_tolerance = nil, ver_tolerance = nil)
        word1, word2 = factory([word1, word2])
        word1.intersects_horizontally?(word2, hor_tolerance) || word1.intersects_vertically?(word2, ver_tolerance)
      end

      def contains?(word1, word2)
        word1, word2 = factory([word1, word2])
        word1.contains?(word2)
      end

      def vertical_gap(word1, word2)
        word1, word2 = factory([word1, word2]).sort_by(&:min_y)
        word2.min_y - word1.max_y
      end

      def horizontal_gap(word1, word2)
        word1, word2 = factory([word1, word2]).sort_by(&:min_x)
        word2.min_x - word1.max_x
      end
    end

    # NOTE!!!: Make sure you update to_h if you're adding something here that you want to be saved to the DB
    def initialize(word)
      @text = word['text']&.to_s
      @vision_text = VisionText.factory(@text)
      @bounds = Bounds.factory(word['bounds'])
      @category = word['category']
      @combined_indices = word['indices'] || word['combined_indices']
      @corrected_text = word['corrected_text']&.to_s || @text
      @vision_corrected_text = VisionText.factory(@corrected_text)
      @polygons = word['polygons']
    end

    def [](key)
      return send(key) if respond_to?(key)
      instance_variable_get("@#{key}")
    end

    def []=(key, value)
      instance_variable_set("@#{key}", value)
    end

    def dig(*args)
      val = self[args.first]
      args.size > 1 ? val&.dig(*args.from(1)) : val
    end

    def fetch(key, default = nil)
      self[key] || default
    end

    def merge(hash)
      hash.each_key { |key| self[key] = hash[key] }
      self
    end

    def font_width
      @font_width ||= width.fdiv(length).round(2)
    end

    def width
      min, max = minmax_x
      (max - min)
    end

    def font_size_ratio
      font_width.fdiv(font_height)
    end

    def match?(regex, use_corrected = false)
      use_corrected ? vision_corrected_text.match?(regex) : vision_text.match?(regex)
    end

    def match(regex, use_corrected = false)
      use_corrected ? vision_corrected_text.match(regex) : vision_text.match(regex)
    end

    def dollar?(options = {})
      strict = options.fetch(:strict, false)

      category == GvaWrapper::DOLLAR_AMOUNTS || vision_text.dollar?(strict: strict)
    end

    def dollar_amount
      vision_text.dollar_amount(skip_regex: true) if dollar?
    end

    def date?
      (category == GvaWrapper::DATES || vision_text.date?) && !dollar?
    end

    def to_date
      vision_text.to_date(skip_regex: true) if date?
    end

    def partial_date?
      !vision_text.date? && (category == GvaWrapper::DATES || vision_text.partial_date?)
    end

    def hours?(options = {})
      strict = options.fetch(:strict, false)

      category == GvaWrapper::HOURS || vision_text.hours?(strict: strict)
    end

    def to_hours
      vision_text.to_hours(skip_regex: true) if hours?
    end

    def hourly_rate?
      category == GvaWrapper::HOURLY_RATE || vision_text.hourly_rate?
    end

    def to_hourly_rate
      vision_text.to_hourly_rate(skip_regex: true) if hourly_rate?
    end

    def ssn?
      category == GvaWrapper::SSN || vision_text.ssn?
    end

    def to_ssn
      vision_text.to_ssn if ssn?
    end

    def vin?
      category == GvaWrapper::VIN || vision_text.vin?
    end

    def to_vin
      vision_text.to_vin if vin?
    end

    def percent?
      category == GvaWrapper::PERCENT || vision_text.percent?
    end

    def to_percent
      vision_text.to_percent if percent?
    end

    def odometer?(options = {})
      min = options.fetch(:min, nil)

      vision_text.odometer?(min: min || 1_000)
    end

    def to_odometer(options = {})
      min = options.fetch(:min, nil)

      vision_text.to_odometer(min: min) if odometer?(min: min)
    end

    def to_int
      vision_text.to_int
    end

    def combined?
      [category, combined_indices].any?(&:present?)
    end

    # given two words, decide if the source word fully contain the given word
    # source word should have all the text in given word, and contain the full bounds of given word too
    def contain_word?(given_word)
      return unless given_word.present?
      return unless text.index(given_word.text).present?
      strictly_contains?(given_word)
    end

    # DO NOT CHANGE. USED FOR COMPARISON.
    def hashed
      { 'text' => text, 'bounds' => bounds.to_h }
    end

    def hash
      hashed.hash
    end

    def char_width
      width / text.size
    end

    def eql?(other)
      hashed == other.hashed
    end

    def to_payload(external: false)
      formatter = external ? 'to_payload' : 'to_h'
      payload = { 'text' => text, 'bounds' => bounds.send(formatter) }
      payload['category'] = category if category.present?
      payload['combined_indices'] = combined_indices if combined_indices.present?
      payload['corrected_text'] = corrected_text if corrected_text.present?
      payload['polygons'] = polygons if polygons.present?
      payload['formatted_value'] = formatted_text
      payload
    end

    alias to_h to_payload

    alias == eql?

    alias inspect to_h
  end
end
