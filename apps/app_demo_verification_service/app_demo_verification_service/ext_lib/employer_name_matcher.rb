module EmployerNameMatcher
  include BingApiHelper

  CLEAN_REGEX ||= /[^a-z0-9 ]/i.freeze
  EMPLOYER_NAME_LOOKUP_ENABLED ||= ENV['EMPLOYER_NAME_LOOKUP_ENABLED']&.match?(/true/i).freeze

  def self.clean(string)
    string.gsub(CLEAN_REGEX, '').squeeze(' ').strip.downcase
  end

  def self.parse_cleaned_json_hash(file)
    file_path = File.join('app_demo_verification_service', 'ext_lib', file)
    JSON.parse(File.read(file_path)).to_h { |k, v| [clean(k), v.map { |e| clean(e) }.uniq] }
  end

  def self.employer_match_lookup_enabled?
    EMPLOYER_NAME_LOOKUP_ENABLED
  end

  AKA ||= EmployerNameMatcher.parse_cleaned_json_hash('employers_aka.json').freeze if EmployerNameMatcher.employer_match_lookup_enabled? # rubocop:disable Layout/LineLength
  FRANCHISEE ||= EmployerNameMatcher.parse_cleaned_json_hash('franchisees.json').freeze if EmployerNameMatcher.employer_match_lookup_enabled? # rubocop:disable Layout/LineLength
  EMPLOYER_MATCH_PREFIX ||= 'employer-name-match'.freeze
  CACHE_TTL ||= 3600 * 24 * 3 # default 3 days

  REJECT_URLS ||= /fool|thestreet|yelp|happycards|invest|stock|linkedin|findagrave|books\.google|glassdoor|reddit|indeed|opinion|facebook|ziprecruiter|ebay/i.freeze # rubocop:disable Layout/LineLength
  BLACK_LISTED ||= /against|sue|provides|rejects/i.freeze

  MISMATCH_LIST ||= [[/american airlines/i, /informed/i]].freeze

  def mismatch_employer?(employer, compare_name)
    MISMATCH_LIST.any? do |r1, r2|
      (employer.match?(r1) && compare_name.match?(r2)) ||
        (compare_name.match?(r1) && employer.match?(r2))
    end
  end

  def usps_employer?(emp_name)
    return false unless emp_name.present?
    usps_names_regex = /(USPS|U\.S\. Postal Service|United States Postal Service|Postmaster\/Manager)/i
    emp_name.match?(usps_names_regex)
  end

  def check_usps(employer, compare_name)
    true if usps_employer?(compare_name) && usps_employer?(employer)
  end

  def substring_match(employer, compare_name)
    sanitized_name = employer.gsub(/[^a-zA-Z0-9\s]/, '')
    sanitized_compare_name = compare_name.gsub(/[^a-zA-Z0-9]/, '')
    sanitized_name_no_space = sanitized_name.gsub(/[\s]/, '')
    # if extracted data is the substring of training data return true
    true if sanitized_name_no_space.match?(/#{Regexp.quote(sanitized_compare_name)}/i) && (sanitized_compare_name.size >= 3 || sanitized_name_no_space.size < 5) # rubocop:disable Layout/LineLength
  end

  def partial_match(employer, compare_name, min_match = 0.6)
    sanitized_name = employer.gsub(/[^a-zA-Z0-9\s]/, '')
    true if employer_name_partial_match?(sanitized_name, compare_name, min_match: min_match)
  end

  def fuzzy_match(employer, compare_name)
    score = fuzzy_match_score(employer, compare_name)
    true if score.present? && score > 0.9
  end

  def sanitize_employer_name(name, options = {})
    use_spell_check = options.fetch(:use_spell_check, false)

    name = name.gsub(/[^a-zA-Z0-9]/, ' ').gsub(/\s+/, ' ').strip
    use_spell_check ? spell_corrector(name) : name
  end

  def remove_common_words_in_employer_name(name, options = {})
    strict = options.fetch(:strict, true)

    common_suffix = /(corp(\.|oration)?|(usa[.,]? )?in[cd](\.|,)?|incorp(orated)?|employer|llc|dept|department|company|center|holdings?|Manufactur(e|ing)|ltd|lp|groups?|solutions|limited|schools?|facility|hospital)$/i # rubocop:disable Layout/LineLength
    common_prefix = /\Aemployer/i
    return name.gsub(/#{common_suffix}|#{common_prefix}/, '').strip if (strict && name.split.size > 3) || !strict
    name
  end

  def remove_common_words_in_lender_name(name)
    common_suffix = /financial|bank/
    name.gsub(/#{common_suffix}/, '').strip
  end

  def employer_name_partial_match?(employer, compare_name, options = {})
    min_match = options.fetch(:min_match, 0.6)

    sanitized_compare_name = compare_name.gsub(/[^a-zA-Z0-9]/, '')
    name_parts = employer.split
    matches_count = 0
    return false if name_parts.all? { |p| p.size == 1 }
    # if there is only one letter difference between two words, make them same
    name_parts.each { |name_part| matches_count += employer_part_name_match(name_part, sanitized_compare_name) }
    matches_count.fdiv(name_parts.count) >= min_match || strip_match?(name_parts, compare_name)
  end

  def sanitized_employer_name_spaces(employer, compare_name)
    sanitized_name_space = remove_common_words_in_employer_name(sanitize_employer_name(employer, use_spell_check: true), strict: false) # rubocop:disable Layout/LineLength
    sanitized_name_space = sanitized_name_space.split.select { |w| w.size > 1 }.join(' ')
    sanitized_name_no_space = sanitized_name_space.gsub(/[\s]/, '')
    sanitized_compare_name_space = remove_common_words_in_employer_name(sanitize_employer_name(compare_name, use_spell_check: true), strict: false) # rubocop:disable Layout/LineLength
    sanitized_compare_name_no_space = sanitized_compare_name_space.gsub(/[\s]/, '')
    [sanitized_name_no_space, sanitized_compare_name_no_space, sanitized_name_space, sanitized_compare_name_space]
  end

  def check_abbreviation(employer, compare_name)
    sanitized_name_no_space, sanitized_compare_name_no_space, _, sanitized_compare_name_space = sanitized_employer_name_spaces(employer, compare_name) # rubocop:disable Layout/LineLength
    return unless [sanitized_name_no_space, sanitized_compare_name_no_space].all?(&:present?)
    return unless (sanitized_name_no_space.size - sanitized_compare_name_space.split.size).between?(0, 2)
    initials = sanitized_compare_name_space.split.map { |w| w[0] }.join
    true if sanitized_name_no_space.match?(/#{Regexp.quote(initials)}/i)
  end

  def check_extracted_data_substring(employer, compare_name)
    sanitized_name_no_space, sanitized_compare_name_no_space, = sanitized_employer_name_spaces(employer, compare_name)
    return unless [sanitized_name_no_space, sanitized_compare_name_no_space].all?(&:present?)
    true if sanitized_name_no_space.match?(/#{Regexp.quote(sanitized_compare_name_no_space)}/i) && (sanitized_compare_name_no_space.size >= 3 || sanitized_name_no_space.size < 5) # rubocop:disable Layout/LineLength
  end

  def check_buyer_data_substring(employer, compare_name)
    sanitized_name_no_space, sanitized_compare_name_no_space, = sanitized_employer_name_spaces(employer, compare_name)
    return unless [sanitized_name_no_space, sanitized_compare_name_no_space].all?(&:present?)
    true if sanitized_compare_name_no_space.match?(/#{Regexp.quote(sanitized_name_no_space)}/i) && (sanitized_name_no_space.size >= 5 && sanitized_compare_name_no_space.size >= 8) # rubocop:disable Layout/LineLength
  end

  def check_ignore_onechar_off(employer, compare_name, min_match = 0.55)
    _, _, sanitized_name_space, sanitized_compare_name_space = sanitized_employer_name_spaces(employer, compare_name)
    return unless [sanitized_name_space, sanitized_compare_name_space].all?(&:present?)
    employer_names = [sanitized_name_space, sanitized_compare_name_space]&.sort_by(&:size)
    return if employer_names.first.split.size.fdiv(employer_names.last.split.size) < 0.3
    return true if employer_name_partial_match?(employer_names.first, employer_names.last, min_match: min_match)
  end

  def check_web(employer, compare_name)
    true if match_through_web_search?(employer, compare_name)
  end

  def spell_corrector(text_str, options = {})
    threshold = options.fetch(:threshold, 0.5)

    results = spell_check(text_str)
    return text_str unless results.present?
    results.each do |change|
      next unless change['suggestions'].present? && change['suggestions'].first['score'] >= threshold
      text_str = text_str.gsub(change['token'], change['suggestions'].first['suggestion'])
    end
    text_str
  end

  def match_employer_names_through_fuzzy_search?(sentences, word1, word2)
    matched_str = fuzzy_search(word1, sentences)
    return false unless matched_str.present?
    sentences = sentences.gsub(/#{matched_str}/i, ' ')
    matched_str = fuzzy_search(word2, sentences)
    matched_str.present?
  end

  def find_employer_name?(name_search, name_find)
    # search name_search, check if name_find in snippet
    search_words = name_search.split.size == 1 & name_search.size <= 4 ? "#{name_search} Inc" : name_search
    results = search_for(search_words)
    return false unless results.present?
    results.each do |link|
      sentences = link['snippet']
      if name_find.split.size == 1 & name_find.size <= 4
        return true if sentences.match?(/\b#{name_find.upcase}\b/)
      elsif sentences.match?(/\b#{name_find}\b/i)
        return true
      end
    end
    false
  end

  def match_employer_names_in_pair?(buyer_info, extracted_data)
    results = search_for("#{extracted_data} #{buyer_info}")
    return false unless results.present?

    loose_buyer_info = buyer_info.split.join(' (and )?')
    loose_extracted_data = extracted_data.split.join(' (and )?')
    negetive_relation = results.any? do |data|
      sentences = data['snippet'].to_s.gsub(/[^a-zA-Z0-9]/, ' ').gsub('  ', ' ').strip
      sentences.match?(/#{loose_buyer_info}.*#{BLACK_LISTED}.*#{loose_extracted_data}/i) ||
        sentences.match?(/#{loose_extracted_data}.*#{BLACK_LISTED}.*#{loose_buyer_info}/i)
    end
    return false if negetive_relation

    filtered_results = results.reject { |data| data['url'].match?(REJECT_URLS) }
    return false if filtered_results.blank?

    filtered_results.any? do |data|
      sentences = data['snippet'].to_s.gsub(/[^a-zA-Z0-9]/, ' ').gsub('  ', ' ').strip
      sentences.match?(/#{loose_buyer_info}.*#{loose_extracted_data}/i) ||
        sentences.match?(/#{loose_extracted_data}.*#{loose_buyer_info}/i) ||
        match_employer_names_through_fuzzy_search?(sentences, buyer_info, extracted_data)
    end
  end

  def match_through_web_search?(buyer_info, extracted_data, options = {})
    use_spell_check = options.fetch(:use_spell_check, true)

    buyer_info = remove_common_words_in_employer_name(sanitize_employer_name(buyer_info, use_spell_check: use_spell_check), strict: true) # rubocop:disable Layout/LineLength
    extracted_data = remove_common_words_in_employer_name(sanitize_employer_name(extracted_data, use_spell_check: use_spell_check), strict: true) # rubocop:disable Layout/LineLength
    match_employer_names_in_pair?(buyer_info, extracted_data) ||
      find_employer_name?(buyer_info, extracted_data) ||
      find_employer_name?(extracted_data, buyer_info)
  end

  def strip_match?(main_parts, compare)
    return unless compare.present?
    main_parts.join.casecmp(compare.gsub(/[-., ]/, '')).zero?
  end

  def employer_part_name_match(name_part, compare_name)
    return 1 if compare_name.match?(/#{Regexp.quote(name_part)}/i)
    return 0 if name_part.size < 3
    (0..name_part.size - 1).each do |i|
      return 1 if compare_name.match?(/#{Regexp.quote(name_part[0, i])}.#{Regexp.quote(name_part[i + 1..])}/i)
    end
    0
  end

  def fuzzy_match_score(str1, str2)
    sanitize_str = proc { |str| str.gsub(/[^\w\s]/, '') }
    str1_chunks = sanitize_str.call(str1).split
    str2_chunks = sanitize_str.call(str2).split
    strs = [str1_chunks, str2_chunks]
    return unless strs.all?(&:present?)
    short, long = strs.sort_by(&:length)
    return if long.length - short.length > 2
    scores = short.map do |a|
      long.map do |b|
        JaroWinkler.distance(a, b, ignore_case: true)
      end.max
    end
    scores.sum.to_f / scores.length
  end

  def employer_aka_lookup(employer, compare_name)
    employer = employer_key(employer, AKA)
    compare_name = EmployerNameMatcher.clean(compare_name)
    AKA[employer]&.any? { |aka| JaroWinkler.distance(aka, compare_name) > 0.97 } ||
      AKA[employer]&.any? { |aka| DamerauLevenshtein.distance(aka, compare_name) <= 1 }
  end

  def franchisee_lookup(employer, compare_name)
    employer = employer_key(employer, FRANCHISEE)
    compare_name = EmployerNameMatcher.clean(compare_name)
    FRANCHISEE[employer]&.any? { |franchisee| JaroWinkler.distance(franchisee, compare_name) > 0.97 } ||
      FRANCHISEE[employer]&.any? { |franchisee| DamerauLevenshtein.distance(franchisee, compare_name) <= 1 }
  end

  def employer_key(employer, hash)
    employer = EmployerNameMatcher.clean(employer)
    return employer if hash.key?(employer)
    substring_matches = hash.keys.filter { |key| key.include?(employer) || employer.include?(key) }
    return substring_matches.first if substring_matches.count == 1
    fuzzy_matches = hash.keys.filter { |key| JaroWinkler.distance(key, employer) > 0.90 || DamerauLevenshtein.distance(key, employer) <= 1 } # rubocop:disable Layout/LineLength
    fuzzy_matches.first if fuzzy_matches.count == 1
  end

  def employer_name_cache_key(employer, compare_name)
    "#{EMPLOYER_MATCH_PREFIX}:#{EmployerNameMatcher.clean(employer)}:#{EmployerNameMatcher.clean(compare_name)}"
  end
end
