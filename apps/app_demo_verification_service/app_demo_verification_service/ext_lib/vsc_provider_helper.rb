module VscProviderHelper
  # Order by Popular names for early match
  PROVIDER_NAMES ||= File.open(File.join('app_demo_verification_service', 'ext_lib', 'vsc_carriers.txt')).to_a.map(&:strip).freeze # rubocop:disable Layout/LineLength

  # WIP: can use concurrency analysis for a thorough list
  AUXILLARY_PROVIDER_MAPPING ||= {
    'FIRST EXTENDED SERVICE CORP' => 'Portfolio Protection',
    'Horizon'                     => 'Portfolio Protection',
    'ALLSTATE MOTOR CLUB'         => 'PABLO CREEK SERVICES INC',
    'AmeriPlus'                   => 'OWNERGUARD CORPORATION',
    'FIRST AUTOMOTIVE'            => 'DEALER ALLIANCE CORPORATION',
    'US PLUS WARRANTY'            => 'AUTO SERVICES COMPANY INC',
    'EchoPark'                    => 'Ally Premier Protection',
    'SecureNet'                   => 'GS Administrators, Inc.',
    'EG Assurance'                => 'ETHOS GROUP INC',
    'Preferred Warranties Inc'    => 'United Service Protection Corp',
    'EXTRA CARE TOYOTA'           => 'Toyota',
    'SecureOne'                   => 'Marathon Administrative Co., Inc'
  }.transform_keys!(&:downcase).freeze

  KEYWORD_BLACKLIST ||= /^(protecti(on|ve)|vehicle|warranty|service|contract|care|coverage|plan|car|dealer|mile(s)|system(s)|finance|insurance|company|\s)+|total$|owned/i.freeze # rubocop:disable Layout/LineLength

  def reject_general_keywords(str_words)
    str_words.reject { |w| sanitize_text(w).match?(KEYWORD_BLACKLIST) }
  end

  def sanitize_text(text)
    text.gsub(/\W/, '')
  end

  def fuzzy_match(str1, str2, similarity = 0.95)
    str1 = sanitize_text(str1)
    str2 = sanitize_text(str2)
    return false if str1.gsub(KEYWORD_BLACKLIST, '').length < 3 || str2.gsub(KEYWORD_BLACKLIST, '').length < 3
    JaroWinkler.distance(str1, str2, ignore_case: true) > similarity
  end

  def substring_match(str, substr, min_length = 5)
    str = sanitize_text(str)
    substr = sanitize_text(substr)
    substr.length >= min_length && str.match?(/#{substr}/i)
  end

  def find_elements_match_carriers(array, name, options = {})
    strict = options.fetch(:strict, false)

    strict ? array.select { |w| w.include?(name) } : array.select { |w| fuzzy_match(w, name) }
  end

  def by_partial_name(str_words)
    return unless str_words&.presence
    str_words = [str_words] unless str_words.is_a?(Array)
    str_words = str_words.map(&:text).compact unless str_words.first.is_a?(String)
    strict_str_words = reject_general_keywords(str_words)
    loose_str_words = str_words - strict_str_words
    return [] unless str_words.present?
    PROVIDER_NAMES.map do |name|
      name if find_elements_match_carriers(strict_str_words, name).present? || find_elements_match_carriers(loose_str_words, name, strict: true).present? # rubocop:disable Layout/LineLength
    end.flatten.compact.uniq
  end

  def by_url(urls)
    PROVIDER_NAMES.map do |name|
      matched_url = find_elements_match_carriers(urls, name)
      next unless matched_url.present?
      url_match_special_case(matched_url) || name
    end.flatten.compact.uniq
  end

  def url_match_special_case(matched_url)
    'Preferred Warranties Inc' if matched_url.count == 1 && matched_url.first == 'warrantys'
  end
end
