module FormNumberMatcher
  class << self
    REVISION_DATE_REGEX ||= /(\(.{,6})?#{Regexp.union(VisionPackage::RegexConstants::ALL_DATE, VisionPackage::RegexConstants::PARTIAL_DATE_REGEX)}[\W\_]*($|\))/i.freeze # rubocop:disable Layout/LineLength

    def split_date_from_form_number(form_number)
      split_revision_date = form_number.match(REVISION_DATE_REGEX).to_a.first
      return [form_number, nil] if split_revision_date.nil?
      split_form_number = form_number.split(/(#{REVISION_DATE_REGEX})/).first
      return [nil, split_revision_date] if split_form_number.nil?
      split_form_number = form_number.gsub(split_revision_date, '') if split_form_number.length < 3
      [split_form_number.strip.gsub(/rev(ision)?\.?$/i, '').strip, split_revision_date.strip]
    end

    def sanitize(form_number)
      form_number&.gsub(/[^a-zA-Z0-9]/, ' ')&.gsub(/\s+/, ' ')
    end

    def clean_for_fuzzy_match(str)
      str.gsub(/form/i, '')
    end

    def form_number_fuzzy_match?(str1, str2, options = {})
      ignore_date = options.fetch(:ignore_date, false)
      score = options.fetch(:score, 0.85)

      str1 = clean_for_fuzzy_match(str1)
      str2 = clean_for_fuzzy_match(str2)
      if ignore_date
        str1 = split_date_from_form_number(str1).first
        str2 = split_date_from_form_number(str2).first
      end
      fuzzy_match?(normalize_ocr(str1), normalize_ocr(str2), score: score)
    end

    def fuzzy_match?(str1, str2, options = {})
      score = options.fetch(:score, 0.85)

      return false if str1.length <= 3 || str2.length <= 3
      JaroWinkler.distance(str1, str2) > score
    end

    def normalize_ocr(str)
      sanitize(str).tr('I', '1').tr('0', 'O').tr('5', 'S').tr('Z', '2').upcase
    end
  end
end
