module ValueMatchers
  include AddressHelper
  include FuzzySearchHelper
  include EmployerNameMatcher
  include VscProviderHelper
  include FormNumberMatcher
  include BingApiHelper

  def address_match?(addr, compare_addr, geocoded_addr = nil, geocoded_compare_addr = nil)
    return unless [addr, compare_addr].all?(&:present?)
    return true if addr.casecmp?(compare_addr)
    geo_addr = old_geo_data?(addr, geocoded_addr) ? GeocodeHelper.geocode(addr) : geocoded_addr
    geocoded_compare_addr = GeocodeHelper.geocode(geocoded_compare_addr) if geocoded_compare_addr.is_a?(String)
    geo_comp_addr = geocoded_compare_addr || GeocodeHelper.geocode(compare_addr)
    return false if street_number_mismatch?(addr, compare_addr, geo_addr, geo_comp_addr)
    return true if geocode_match?(geo_addr, geo_comp_addr)
    full_address_match?(geo_addr&.full_address, geo_comp_addr&.full_address) ||
      full_address_match?(geo_addr&.full_address, compare_addr) ||
      full_address_match?(addr, compare_addr)
  end

  def old_geo_data?(buyer_addr, buyer_addr_geocode)
    return true if buyer_addr_geocode.nil?
    addr_match = buyer_addr.match(address_regex)
    addr_match.nil? || (addr_match[:zip].present? && addr_match[:zip] != buyer_addr_geocode.zip)
  end

  def street_number_mismatch?(addr, compare_addr, geo_addr, geo_comp_addr)
    return false if [geo_addr.street_number, geo_comp_addr.street_number].all?(&:present?) && geo_comp_addr.street_number == geo_addr.street_number # rubocop:disable Layout/LineLength
    compare_addr = compare_addr&.full_address unless compare_addr.is_a?(String)
    addr_match = addr.match(address_regex)
    compare_match = compare_addr&.match(address_regex)
    comp_street_num = compare_match.present? ? compare_match[:street_num]&.tr('-', '') : geo_comp_addr&.street_number
    return true if addr_match.present? && comp_street_num.nil?
    [addr_match, comp_street_num].all? && addr_match[:street_num].present? && addr_match[:street_num].tr('-', '') != comp_street_num # rubocop:disable Layout/LineLength
  end

  def full_address_match?(addr, compare_addr)
    return false unless addr.present? && compare_addr.present?
    split_addr = sanitize_split_addr(addr)
    matches = split_addr & sanitize_split_addr(compare_addr)
    (matches.count / split_addr.count.to_f) >= 0.8 || smarter_address_match?(addr, compare_addr) || address_string_match?(addr, compare_addr) # rubocop:disable Layout/LineLength
  end

  def address_string_match?(addr1, addr2, threshold = 0.9)
    addr1 = addr1.gsub(/[^0-9a-z ]|usa/i, ' ').squish
    addr2 = addr2.gsub(/[^0-9a-z ]|usa/i, ' ').squish
    JaroWinkler.distance(addr1, addr2) >= threshold
  end

  def smarter_address_match?(addr, compare_addr)
    addr_match = addr.match(address_regex)
    compare_match = compare_addr.match(address_regex)
    return false unless [addr_match, compare_match].all?
    return false unless addr_match[:street_num] == compare_match[:street_num]
    return false unless addr_match[:street_name]&.gsub(/[^0-9a-z ]/i, '')&.casecmp?(compare_match[:street_name]&.gsub(/[^0-9a-z ]/i, '')) # rubocop:disable Layout/LineLength
    return false unless addr_match[:city]&.gsub(/[^0-9a-z ]/i, '')&.casecmp?(compare_match[:city]&.gsub(/[^0-9a-z ]/i, '')) # rubocop:disable Layout/LineLength
    addr_match[:zip]&.split('-')&.first&.casecmp?(compare_match[:zip]&.split('-')&.first)
  end

  def geocode_match?(addr, compare_addr)
    return unless [addr, compare_addr].all?
    return true if geocode_distance_match?(addr, compare_addr)
    %i[street_number street_name city state_name zip].all? { |field| addr.send(field) == compare_addr.send(field) }
  end

  def geocode_distance_match?(addr, compare_addr, threshold = 0.01)
    return unless [addr.lat, addr.lng, compare_addr.lat, compare_addr.lng].all?
    addr_location = Geokit::LatLng.new(addr.lat, addr.lng)
    compare_addr_location = "#{compare_addr.lat},#{compare_addr.lng}"
    addr_location.distance_to(compare_addr_location) <= threshold
  end

  def sanitize_split_addr(addr)
    return if addr.is_a?(Hash)
    addr.split.map { |s| s.downcase.gsub(/[^0-9a-z]/i, '') }
  end

  def employer_name_match?(employer, compare_name, options = {})
    online_search = options.fetch(:online_search, true)
    strict = options.fetch(:strict, false)

    return unless [employer, compare_name].all?(&:present?)
    return false if mismatch_employer?(employer, compare_name)

    # TODO: CACHE_TTL ?
    name_match_cache = Caches::NameMatch.new(employer, compare_name)
    cached_result = name_match_cache.fetch
    return cached_result == true if cached_result.present?
    match = check_usps(employer, compare_name) || substring_match(employer, compare_name) ||
            partial_match(employer, compare_name) || fuzzy_match(employer, compare_name) ||
            check_abbreviation(employer, compare_name) || check_buyer_data_substring(employer, compare_name)
    match = match || check_extracted_data_substring(employer, compare_name) || check_ignore_onechar_off(employer, compare_name) unless strict # rubocop:disable Layout/LineLength
    match = match || employer_aka_lookup(employer, compare_name) || franchisee_lookup(employer, compare_name) || employer_aka_lookup(compare_name, employer) || franchisee_lookup(compare_name, employer) if EmployerNameMatcher.employer_match_lookup_enabled? # rubocop:disable Layout/LineLength
    match = match || (online_search && check_web(employer, compare_name)) || false

    name_match_cache.insert(result: match)
    match
  end

  def phone_match?(phone, compare_phone)
    return unless [phone, compare_phone].all?
    source_phone = PhoneNumberUtil.national_phone_number(phone)
    compare_phone = PhoneNumberUtil.national_phone_number(compare_phone)
    source_phone.present? && source_phone == compare_phone
  end

  def name_match?(name, compare_name, buyer_with_middle_name = nil)
    return unless [name, compare_name].all?(&:present?)
    split_name = sanitize_split_name(name)
    split_compare_name = sanitize_split_name(compare_name)
    return if split_compare_name.count == 1
    return true if compare_names_match?(split_name, split_compare_name)
    if buyer_with_middle_name
      split_buyer = sanitize_split_name(buyer_with_middle_name)
      return true if compare_names_match?(split_buyer, split_compare_name)
    end
    off_by_one_match?(split_name, split_compare_name) ||
      char_match?(split_name, split_compare_name) ||
      nickname_match?(split_name, split_compare_name)
  end

  def dealer_name_match?(name, compare_name)
    if name.present? && compare_name.present?
      jaro_winkler_match = JaroWinkler.distance(name.downcase,
                                                compare_name.downcase) > 0.9
    end
    name_match?(name, compare_name) || jaro_winkler_match
  end

  def nickname_match?(split_name, split_compare_name)
    ct = split_name.count do |name_node|
      split_compare_name.any? do |compare_node|
        candidates = NickNameList[name_node.downcase] || [name_node]
        candidates&.any? { |nickname| nickname.casecmp?(compare_node) }
      end
    end
    ct > (split_name.count * 0.5)
  end

  def compare_names_match?(a, b)
    matched = compare_with_spelling_mistakes(a, b)
    score = matched.count.fdiv(a.count)
    score > 0.6 || (matched.count >= 2 && score >= 0.5)
  end

  def compare_with_spelling_mistakes(a, b)
    a.map do |a_node|
      b.select do |b_node|
        JaroWinkler.distance(a_node, b_node, adj_table: true) > 0.80
      end
    end.flatten.compact.uniq
  end

  def off_by_one_match?(split_name, split_compare_name)
    matched = compare_with_spelling_mistakes(split_name, split_compare_name)
    name_leftover = split_name - matched
    compare_name_leftover = split_compare_name - matched
    return false unless name_leftover.count == 1 && name_leftover.count == compare_name_leftover.count
    DamerauLevenshtein.distance(name_leftover.first.downcase, compare_name_leftover.first.downcase) == 1
  end

  def char_match?(split_name, split_compare_name)
    split_name.join == split_compare_name.join
  end

  def sanitize_split_name(name)
    name&.downcase&.gsub(/[^a-z\- ]/i, '')&.tr('-', ' ')&.split(' ') || []
  end

  def income_match?(a, b, tolerance = 0.05)
    (a - b).abs.fdiv(a) < tolerance
  end

  def remove_non_digit_char(text)
    return unless text.present?
    text.gsub(/\D/, '')
  end

  def dealer_field_match?(source, compare, tolerance = 0.01)
    return source == compare if [source, compare].all? { |v| v.is_a?(String) }
    return false if source.to_f.zero?
    (source.to_f - compare.to_f).abs.fdiv(source.to_f) < tolerance
  end

  def ssn_match?(source, compare)
    return false unless source.present? && compare.present?
    clean_source = remove_non_digit_char(source)
    clean_compare = remove_non_digit_char(compare)
    return if (clean_source.length != 4 && clean_source.length != 9) || (clean_compare.length != 4 && clean_compare.length != 9) # rubocop:disable Layout/LineLength
    return clean_source == clean_compare if clean_source.length == clean_compare.length
    full, partial = clean_source.length > clean_compare.length ? [clean_source, clean_compare] : [clean_compare, clean_source] # rubocop:disable Layout/LineLength
    full.match?(/#{partial}$/)
  end

  def pay_date_match?(source, compare)
    source, compare = [source, compare].map { |val| VisionPackage::VisionText.to_date(val) }
    [source, compare].all?(&:present?) && (source - compare).to_i.abs <= 3
  end

  def vsc_equivalent_carrier(carrier_name)
    AUXILLARY_PROVIDER_MAPPING[carrier_name.downcase] || carrier_name
  end

  def vsc_provider_match?(source, compare)
    return false unless source && compare
    providers = [VisionPackage::RegexConstants::VSC_PROVIDER_AUL, VisionPackage::RegexConstants::GAP_PROVIDER_GMAC]
    return true if providers.any? { |reg| source.match?(reg) && compare.match?(reg) }
    employer_name_match?(source, compare) || loose_santized_match?(source, compare, 0.85) || employer_name_match?(vsc_equivalent_carrier(source), vsc_equivalent_carrier(compare)) # rubocop:disable Layout/LineLength
  end

  def gap_provider_match?(source, compare)
    return false unless source && compare
    providers = [VisionPackage::RegexConstants::GAP_PROVIDER_GMAC, VisionPackage::RegexConstants::GAP_PROVIDER_JMA, VisionPackage::RegexConstants::GAP_PROVIDER_US, VisionPackage::RegexConstants::GAP_PROVIDER_AHIS, VisionPackage::RegexConstants::GAP_PROVIDER_IAS, VisionPackage::RegexConstants::GAP_PROVIDER_AWS, VisionPackage::RegexConstants::GAP_PROVIDER_NAS, VisionPackage::RegexConstants::GAP_PROVIDER_PDS, VisionPackage::RegexConstants::GAP_PROVIDER_CSCI, VisionPackage::RegexConstants::GAP_PROVIDER_TMIS, VisionPackage::RegexConstants::GAP_PROVIDER_EXPRESS, VisionPackage::RegexConstants::GAP_PROVIDER_SAFEGUARD, VisionPackage::RegexConstants::GAP_PROVIDER_APPI, VisionPackage::RegexConstants::GAP_PROVIDER_NORMAN, VisionPackage::RegexConstants::GAP_PROVIDER_LDS, VisionPackage::RegexConstants::GAP_PROVIDER_CARCO, VisionPackage::RegexConstants::GAP_PROVIDER_AMERICAN, VisionPackage::RegexConstants::GAP_PROVIDER_TASA, VisionPackage::RegexConstants::GAP_PROVIDER_SOUTHWEST] # rubocop:disable Layout/LineLength
    return true if providers.any? { |reg| source.match?(reg) && compare.match?(reg) } || compare.match?(/N\/A/)
    employer_name_match?(source, compare, online_search: false, strict: true) || loose_santized_match?(source, compare, 0.85) || employer_name_match?(vsc_equivalent_carrier(source), vsc_equivalent_carrier(compare)) # rubocop:disable Layout/LineLength
  end

  def vin_match?(a, b)
    loose_match?(a, b, 0.9)
  end

  def loose_santized_match?(a, b, threshold)
    loose_match?(a.gsub(/[-., ]/, ''), b.gsub(/[-., ]/, ''), threshold)
  end

  def loose_match?(a, b, threshold)
    JaroWinkler.distance(a&.to_s, b&.to_s, ignore_case: true) > threshold
  end

  def signature_match?(a, b)
    return false unless [a, b].all? { |v| v.in? %w[true false] }
    a == b
  end

  def vsc_from_number_fuzzy_match?(a, b, threshold)
    FormNumberMatcher.form_number_fuzzy_match?(a, b, ignore_date: false, score: threshold) ||
      substring_match(a, b) || substring_match(b, a)
  end
end
