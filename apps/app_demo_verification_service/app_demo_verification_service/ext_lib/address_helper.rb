module AddressHelper
  require 'English'

  include VisionPackage::GeometryHelper
  include VisionPackage::DocumentOcrAnalysis
  include VisionPackage::VisionWordsHelper

  ALL_STATE_NAMES ||= {
    'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR', 'California': 'CA', 'Colorado': 'CO',
    'Connecticut': 'CT', 'Delaware': 'DE', 'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI', 'Idaho': 'ID',
    'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA', 'Kansas': 'KS', 'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME',
    'Maryland': 'MD', 'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN', 'Mississippi': 'MS', 'Missouri': 'MO',
    'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV', 'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM',
    'New York': 'NY', 'North Carolina': 'NC', 'North Dakota': 'ND', 'Ohio': 'OH', 'Oklahoma': 'OK', 'Oregon': 'OR',
    'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC', 'South Dakota': 'SD', 'Tennessee': 'TN',
    'Texas': 'TX', 'Utah': 'UT', 'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
    'Wisconsin': 'WI', 'Wyoming': 'WY'
  }.freeze

  # For Bad OCR cases - one of the two characters in state abbreviation is misrecognized
  LOOSE_ALL_STATE_NAMES ||= {
    'Alabama':        %w[AI],
    'Alaska':         %w[],
    'Arizona':        %w[A2 A7],
    'Arkansas':       %w[AF],
    'California':     %w[],
    'Colorado':       %w[GO CD CU CQ C0 GD GU GQ G0],
    'Connecticut':    %w[GT CI C7 GI G7],
    'Delaware':       %w[OE 0E DF OF],
    'Florida':        %w[EL 7L FI EI 7I],
    'Georgia':        %w[],
    'Hawaii':         %w[HT HL],
    'Idaho':          %w[TD LD IO I0 IU TO T0 TU LO L0 LU],
    'Illinois':       %w[TL LL II TI LI],
    'Indiana':        %w[TN LN IM TM LM],
    'Iowa':           %w[TA],
    'Kansas':         %w[K5 K8],
    'Kentucky':       %w[KV KX],
    'Louisiana':      %w[],
    'Maine':          %w[MF NF],
    'Maryland':       %w[],
    'Massachusetts':  %w[NA],
    'Michigan':       %w[NI ML NL],
    'Minnesota':      %w[NN],
    'Mississippi':    %w[NS M5 M8 N5 N8],
    'Missouri':       %w[NO N0],
    'Montana':        %w[NT],
    'Nebraska':       %w[NF],
    'Nevada':         %w[MV MU],
    'New Hampshire':  %w[MH],
    'New Jersey':     %w[MJ],
    'New Mexico':     %w[MM],
    'New York':       %w[MY MV NX MX],
    'North Carolina': %w[NG MG MC],
    'North Dakota':   %w[NO],
    'Ohio':           %w[DH 0H],
    'Oklahoma':       %w[DK 0K],
    'Oregon':         %w[OF DR 0R 0F],
    'Pennsylvania':   %w[BA],
    'Rhode Island':   %w[RT RL FT],
    'South Carolina': %w[SG 5G 8G 5C 8C],
    'South Dakota':   %w[SO S0 5D 8D 5O 50 8O 80],
    'Tennessee':      %w[],
    'Texas':          %w[IX LX IY LY TY],
    'Utah':           %w[OT DT UI UL OI OL DI DL],
    'Vermont':        %w[YT],
    'Virginia':       %w[YA],
    'Washington':     %w[WA],
    'West Virginia':  %w[WY],
    'Wisconsin':      %w[WT WL],
    'Wyoming':        %w[WV WX]
  }.freeze

  STATE_ABBREVIATIONS ||= ALL_STATE_NAMES.values.freeze
  LOOSE_STATE_ABBREVIATIONS ||= LOOSE_ALL_STATE_NAMES.values.flatten.freeze

  FULL_STATES ||= ALL_STATE_NAMES.keys.freeze

  FULL_STATES_TYPOS ||= ['Ulah'].freeze

  MULTI_WORD_STATES ||= { 'West Virginia': 'WV', 'Washington, DC': 'DC', 'District of Columbia': 'DC', 'Washington DC': 'DC' }.freeze # rubocop:disable Layout/LineLength

  MULTI_WORD_STATE_REGEX ||= MULTI_WORD_STATES.values.freeze

  STREET_ABBREVIATIONS ||= {
    'ALLEY':      %w[ALLEE ALLEY ALLY ALY],
    'ANEX':       %w[ANEX ANNEX ANNX ANX],
    'ARCADE':     %w[ARC ARCADE],
    'AVENUE':     %w[AV AVE AVEN AVENU AVENUE AVN AVNUE],
    'BAYOU':      %w[BAYOO BAYOU BYU],
    'BEACH':      %w[BCH BEACH],
    'BEND':       %w[BEND BND],
    'BLUFF':      %w[BLF BLUF BLUFF],
    'BLUFFS':     %w[BLUFFS BLFS],
    'BOTTOM':     %w[BOT BTM BOTTM BOTTOM],
    'BOULEVARD':  %w[BLVD BOUL BOULEVARD BOULV],
    'BRANCH':     %w[BR BRNCH BRANCH],
    'BRIDGE':     %w[BRDGE BRG BRIDGE],
    'BROOK':      %w[BRK BROOK],
    'BROOKS':     %w[BROOKS BRKS],
    'BURG':       %w[BURG BG],
    'BURGS':      %w[BURGS BGS],
    'BYPASS':     %w[BYP BYPA BYPAS BYPASS BYPS],
    'CAMP':       %w[CAMP CP CMP],
    'CANYON':     %w[CANYN CANYON CNYN CYN],
    'CAPE':       %w[CAPE CPE],
    'CAUSEWAY':   %w[CAUSEWAY CAUSWA CSWY],
    'CENTER':     %w[CEN CENT CENTER CENTR CENTRE CNTER CNTR CTR],
    'CENTERS':    %w[CENTERS CTRS],
    'CIRCLE':     %w[CIR CIRC CIRCL CIRCLE CRCL CRCLE],
    'CIRCLES':    %w[CIRCLES CIRS],
    'CLIFF':      %w[CLF CLIFF],
    'CLIFFS':     %w[CLFS CLIFFS],
    'CLUB':       %w[CLB CLUB],
    'COMMON':     %w[COMMON CMN],
    'COMMONS':    %w[COMMONS CMNS],
    'CORNER':     %w[COR CORNER],
    'CORNERS':    %w[CORNERS CORS],
    'COURSE':     %w[COURSE CRSE],
    'COURT':      %w[COURT CT],
    'COURTS':     %w[COURTS CTS],
    'COVE':       %w[COVE CV],
    'COVES':      %w[COVES CVS],
    'CREEK':      %w[CREEK CRK],
    'CRESCENT':   %w[CRESCENT CRES CRSENT CRSNT],
    'CREST':      %w[CREST CRST],
    'CROSSING':   %w[CROSSING CRSSNG XING XING],
    'CROSSROAD':  %w[CROSSROAD XRD],
    'CROSSROADS': %w[CROSSROADS XRDS],
    'CURVE ':     %w[CURVE CURV],
    'DALE':       %w[DALE DL DL],
    'DAM':        %w[DAM DM DM],
    'DIVIDE':     %w[DIV DIVIDE DV DVD],
    'DRIVE':      %w[DR DRIV DRIVE DRV],
    'DRIVES':     %w[DRIVES DRS],
    'ESTATE':     %w[EST ESTATE],
    'ESTATES':    %w[ESTATES ESTS],
    'EXPRESSWAY': %w[EXP EXPR EXPRESS EXPRESSWAY EXPW EXPY],
    'EXTENSION':  %w[EXT EXTENSION EXTN EXTNSN],
    'EXTENSIONS': %w[EXTS],
    'FALL':       %w[FALL],
    'FALLS':      %w[FALLS FLS],
    'FERRY':      %w[FERRY FRRY FRY],
    'FIELD':      %w[FIELD FLD],
    'FIELDS':     %w[FIELDS FLDS],
    'FLAT':       %w[FLAT FLT],
    'FLATS':      %w[FLATS FLTS],
    'FORD':       %w[FORD FRD],
    'FORDS':      %w[FORDS FRDS],
    'FOREST':     %w[FOREST FORESTS FRST],
    'FORGE':      %w[FORG FORGE FRG],
    'FORGES':     %w[FORGES FRGS],
    'FORK':       %w[FORK FRK],
    'FORKS':      %w[FORKS FRKS],
    'FORT':       %w[FORT FRT FT],
    'FREEWAY':    %w[FREEWAY FREEWY FRWAY FRWY FWY],
    'GARDEN':     %w[GARDEN GARDN GRDEN GRDN GDN],
    'GARDENS':    %w[GARDENS GDNS GRDNS],
    'GATEWAY':    %w[GATEWAY GATEWY GATWAY GTWAY GTWY],
    'GLEN':       %w[GLEN GLN],
    'GLENS':      %w[GLENS GLNS],
    'GREEN':      %w[GREEN GRN],
    'GREENS':     %w[GREENS GRNS],
    'GROVE':      %w[GROV GROVE GRV],
    'GROVES':     %w[GROVES GRVS],
    'HARBOR':     %w[HARB HARBOR HARBR HBR HRBOR],
    'HARBORS':    %w[HARBORS HBRS],
    'HAVEN':      %w[HAVEN HVN],
    'HEIGHTS':    %w[HT HTS],
    'HIGHWAY':    %w[HIGHWAY HIGHWY HIWAY HIWY HWAY HWY],
    'HILL':       %w[HILL HL],
    'HILLS':      %w[HILLS HLS],
    'HOLLOW':     %w[HLLW HOLLOW HOLLOWS HOLW HOLWS],
    'INLET':      %w[INLT],
    'ISLAND':     %w[IS ISLAND ISLND],
    'ISLANDS':    %w[ISLANDS ISLNDS ISS],
    'ISLE':       %w[ISLE ISLES],
    'JUNCTION':   %w[JCT JCTION JCTN JUNCTION JUNCTN JUNCTON],
    'JUNCTIONS':  %w[JCTNS JCTS JUNCTIONS],
    'KEY':        %w[KEY KY],
    'KEYS':       %w[KEYS KYS],
    'KNOLL':      %w[KNL KNOL KNOLL KNL],
    'KNOLLS':     %w[KNLS KNOLLS],
    'LAKE':       %w[LK LAKE],
    'LAKES':      %w[LKS LAKES],
    'LAND':       %w[LAND],
    'LANDING':    %w[LANDING LNDG LNDNG],
    'LANE':       %w[LANE LN],
    'LIGHT':      %w[LGT LIGHT],
    'LIGHTS':     %w[LIGHTS LGTS],
    'LOAF':       %w[LF LOAF],
    'LOCK':       %w[LCK LOCK],
    'LOCKS':      %w[LCKS LOCKS],
    'LODGE':      %w[LDG LDGE LODG LODGE],
    'LOOP':       %w[LOOP LOOPS],
    'MALL':       %w[MALL],
    'MANOR':      %w[MNR MANOR],
    'MANORS':     %w[MANORS MNRS],
    'MEADOW':     %w[MEADOW MDW],
    'MEADOWS':    %w[MDW MDWS MEADOWS MEDOWS],
    'MEWS':       %w[MEWS],
    'MILL':       %w[MILL ML],
    'MILLS':      %w[MILLS MLS],
    'MISSION':    %w[MISSN MSSN MSN],
    'MOTORWAY':   %w[MOTORWAY MTWY],
    'MOUNT':      %w[MNT MT MOUNT],
    'MOUNTAIN':   %w[MNTAIN MNTN MOUNTAIN MOUNTIN MTIN MTN],
    'MOUNTAINS':  %w[MNTNS MOUNTAINS MTNS],
    'NECK':       %w[NCK NECK],
    'ORCHARD':    %w[ORCH ORCHARD ORCHRD],
    'OVAL':       %w[OVAL OVL],
    'OVERPASS':   %w[OVERPASS OPAS],
    'PARK':       %w[PARK PRK],
    'PARKS':      %w[PARKS PARK],
    'PARKWAY':    %w[PARKWAY PARKWY PKWAY PKWY PKY],
    'PARKWAYS':   %w[PARKWAYS PKWYS PKWY],
    'PASS':       %w[PASS],
    'PASSAGE':    %w[PASSAGE PSGE],
    'PATH':       %w[PATH PATHS],
    'PIKE':       %w[PIKE PIKES],
    'PINE':       %w[PINE PNE],
    'PINES':      %w[PINES PNES],
    'PLACE':      %w[PL],
    'PLAIN':      %w[PLAIN PLN],
    'PLAINS':     %w[PLAINS PLNS],
    'PLAZA':      %w[PLAZA PLZ PLZA],
    'POINT':      %w[POINT PT],
    'POINTS':     %w[POINTS PTS],
    'PORT':       %w[PORT PRT],
    'PORTS':      %w[PORTS PRTS],
    'PRAIRIE':    %w[PR PRAIRIE PRR],
    'RADIAL':     %w[RAD RADIAL RADIEL RADL],
    'RAMP':       %w[RAMP],
    'RANCH':      %w[RANCH RANCHES RNCH RNCHS],
    'RAPID':      %w[RAPID RPD],
    'RAPIDS':     %w[RAPIDS RPDS],
    'REST':       %w[REST RST],
    'RIDGE':      %w[RDG RDGE RIDGE],
    'RIDGES':     %w[RDGS RIDGES],
    'RIVER':      %w[RIV RIVER RVR RIVR],
    'ROAD':       %w[RD ROAD],
    'ROADS':      %w[ROADS RDS],
    'ROUTE':      %w[ROUTE RTE],
    'ROW':        %w[ROW],
    'RUE':        %w[RUE],
    'RUN':        %w[RUN],
    'SHOAL':      %w[SHL SHOAL],
    'SHOALS':     %w[SHLS SHOALS],
    'SHORE':      %w[SHOAR SHORE SHR],
    'SHORES':     %w[SHOARS SHORES SHRS],
    'SKYWAY':     %w[SKYWAY SKWY],
    'SPRING':     %w[SPG SPNG SPRING SPRNG],
    'SPRINGS':    %w[SPGS SPNGS SPRINGS SPRNGS],
    'SPUR':       %w[SPUR],
    'SPURS':      %w[SPURS SPUR],
    'SQUARE':     %w[SQ SQR SQRE SQU SQUARE],
    'SQUARES':    %w[SQRS SQUARES SQS],
    'STATION':    %w[STA STATION STATN STN],
    'STRAVENUE':  %w[STRA STRAV STRAVEN STRAVENUE STRAVN STRVN STRVNUE],
    'STREAM':     %w[STREAM STREME STRM],
    'STREET':     %w[STREET STRT ST STR],
    'STREETS':    %w[STREETS STS],
    'SUMMIT':     %w[SMT SUMIT SUMITT SUMMIT],
    'TERRACE':    %w[TER TERR TERRACE],
    'THROUGHWAY': %w[THROUGHWAY TRWY],
    'TRACE':      %w[TRACE TRACES TRCE],
    'TRACK':      %w[TRACK TRACKS TRAK TRK TRKS],
    'TRAFFICWAY': %w[TRAFFICWAY TRFY],
    'TRAIL':      %w[TRAIL TRAILS TRL TRLS],
    'TRAILER':    %w[TRAILER TRLR TRLRS],
    'TUNNEL':     %w[TUNEL TUNL TUNLS TUNNEL TUNNELS TUNNL],
    'TURNPIKE':   %w[TRNPK TURNPIKE TURNPK TPKE],
    'UNDERPASS':  %w[UNDERPASS UPAS],
    'UNION':      %w[UN UNION],
    'UNIONS':     %w[UNIONS UNS],
    'VALLEY':     %w[VALLEY VALLY VLLY VLY],
    'VALLEYS':    %w[VALLEYS VLYS],
    'VIADUCT':    %w[VDCT VIA VIADCT VIADUCT],
    'VIEW':       %w[VIEW VW],
    'VIEWS':      %w[VIEWS VWS],
    'VILLAGE':    %w[VILL VILLAG VILLAGE VILLG VILLIAGE VLG],
    'VILLAGES':   %w[VILLAGES VLGS],
    'VILLE':      %w[VILLE VL],
    'VISTA':      %w[VIS VIST VISTA VST VSTA],
    'WALK':       %w[WALK],
    'WALKS':      %w[WALKS WALK],
    'WALL':       %w[WALL],
    'WAY':        %w[WY WAY],
    'WAYS':       %w[WAYS],
    'WELL':       %w[WELL WL],
    'WELLS':      %w[WELLS WLS]
  }.freeze

  ALL_STREET_ABBREVIATIONS ||= STREET_ABBREVIATIONS.values.flatten.uniq.freeze
  PO_BOX_REGEX ||= /(?<po_box>P(\.)?O(\.)?\s?B(O)?X [1-9]{1}[0-9\-]*)/i.freeze
  STREET_NUM_REGEX ||= /(?<street_num>([NEWS]{1,2}(\.)? )?[1-9]{1}[0-9\-]*(a|b|c)?( [0-9]+\/[0-9]+)?)/i.freeze
  # TODO: Street suffix is currently optional to be lenient, we should start with strict matching and fall back to
  # lenient matching. Basically since suffix is optional it's never actually matching so it's considering any suffixes
  # to be part of the street name
  STREET_SUFFIX_REGEX ||= /(?<street_suffix>(#{ALL_STREET_ABBREVIATIONS.join('|')})[\.,]?)/i.freeze
  APT_REGEX ||= /(?<apt>(((apt|ap|at|pt|unit|ut|uni|unt|suite|ste|st|lot|#){,2}?[ \.]*( )*[A-Z]?[0-9\-]*((\-)?[a-zA-Z])?))?)/i.freeze # rubocop:disable Layout/LineLength
  CITY_REGEX ||=  /(?<city>[a-zA-Z\.,\- ]+)/i.freeze
  STATE_REGEX ||= /(?<state>(#{(STATE_ABBREVIATIONS + FULL_STATES + FULL_STATES_TYPOS).flatten.join('|')}))/i.freeze
  ZIP_REGEX ||= /(?<zip>[0-9]{4,5}(\-?[0-9o]{4})?)?/i.freeze
  STRICT_ZIP_REGEX ||= /^\d{5}(?:[-\s]\d{4})?$/.freeze
  FULL_PO_BOX_REGEX ||= /#{PO_BOX_REGEX}[ \.,]? #{CITY_REGEX} #{STATE_REGEX} #{ZIP_REGEX}/i.freeze
  STATE_ZIP_REGEX ||= /(?:#{(STATE_ABBREVIATIONS + FULL_STATES + FULL_STATES_TYPOS + MULTI_WORD_STATE_REGEX).flatten.join('|')})\,? ?\d{5}/i.freeze # rubocop:disable Layout/LineLength
  STATE_ZIP_LOOSE_REGEX ||= /(?:#{(LOOSE_STATE_ABBREVIATIONS + FULL_STATES + FULL_STATES_TYPOS + MULTI_WORD_STATE_REGEX).flatten.join('|')})\,? ?\d{5}/i.freeze # rubocop:disable Layout/LineLength
  STATE_ZIP_BLACKLIST_REGEX ||= /atm|withdrawal|purchase|pos|non|authorit|http|statement/i.freeze

  ZIP_CODE_DEFAULT ||= 94_070
  HOME_ADDRESS_TYPES ||= %w[route political locality point_of_interest intersection country transit_station bus_station].freeze # rubocop:disable Layout/LineLength

  def street_name_regex(exclusions)
    name_exclusions = /(employee|status|exempt#{exclusions.present? ? "|#{exclusions.join('|')}" : ''})/i
    /(?<street_name>(?!#{name_exclusions})[a-zA-Z\.,\- ]*([1-9]{1}\d{0,2}(st|nd|rd|th|tr))?[a-zA-Z\., ]*)/i
  end

  def address_regex(exclusions = [])
    /(\A| )(#{STREET_NUM_REGEX} #{street_name_regex(exclusions)} (#{STREET_SUFFIX_REGEX}( |,( )?))?(#{APT_REGEX}( |,( )?))?#{CITY_REGEX}( |,( )?)#{STATE_REGEX}( |,( )?)#{ZIP_REGEX}(, USA)?)|(#{FULL_PO_BOX_REGEX})( |\z|)/i # rubocop:disable Layout/LineLength
  end

  def sanitize_split_addr(addr)
    addr.split.map { |s| s.downcase.gsub(/[^0-9a-z]/i, '') }
  end

  def address_hash(addr)
    match_data = addr.match(FULL_PO_BOX_REGEX) if addr.is_a?(String)
    geocoded = addr unless match_data

    match_data = (match_data.names.map(&:to_sym).zip(match_data.captures).to_h if match_data.is_a?(MatchData))

    street_addr = match_data.present? ? match_data[:match_data] : geocoded&.street_address
    street_num = match_data.present? ? nil : geocoded&.street_number
    street2 = match_data.present? ? match_data[:apt] : geocoded&.sub_premise
    street_name = match_data.present? ? match_data[:street_name] : geocoded&.street_name
    city = match_data.present? ? match_data[:city] : geocoded&.city
    state = match_data.present? ? match_data[:state] : geocoded&.state
    state_name = match_data.present? ? match_data[:state] : geocoded&.state_name
    zip = match_data.present? ? match_data[:zip] : geocoded&.zip
    lat = match_data.present? ? nil : geocoded&.lat
    lng = match_data.present? ? nil : geocoded&.lng

    {
      street_address: street_addr,
      street_number:  street_num,
      street_2:       street2.present? ? "##{street2}" : nil,
      street_name:    street_name,
      city:           city,
      state:          state,
      state_name:     state_name,
      zip:            zip,
      lat:            lat,
      lng:            lng,
      full:           match_data ? addr : geocoded&.full_address
    }
  end

  # TODO: This should be smarter
  def fix_address(raw_address, geocoded)
    return unless raw_address.present? && geocoded.present?
    raw_street_num = raw_address.split.first
    geo_split = geocoded.full_address.split
    return unless raw_street_num.present? && geocoded.street_number != raw_street_num
    geo_split[0] = raw_street_num if geocoded.street_number.present?
    geo_split.unshift(raw_street_num) unless geocoded.street_number.present?
    geocoded.street_address = "#{raw_street_num} #{geocoded.street_address.split.from(1).join(' ')}" if geocoded.street_address.present? # rubocop:disable Layout/LineLength
    geocoded.full_address = geo_split.join(' ')
    geocoded.street_number = raw_street_num
    geocoded
  end

  def find_match_with_index(text, regex)
    matches = []
    text.scan(regex) do |match|
      matches << [match, $LAST_MATCH_INFO.offset(0)[0]] # we want to get matches and their index
    end
    matches
  end

  def find_match_index_only(text, regex)
    matches = []
    text.scan(regex) do |_|
      matches << [$LAST_MATCH_INFO.offset(0)[0]]
    end
    matches.flatten
  end

  def words_between_street_num_and_zip(words, num_indices, zip_indices)
    words_btwn = []
    num_indices.each do |index|
      zip_indices.each do |z_index|
        next unless z_index > index
        words_arr = words[index...z_index]
        words_arr << words[z_index].first(5)
        words_btwn << words_arr.uniq
        break
      end
    end
    words_btwn
  end

  def find_closest_match(matches, indices)
    closest_match = matches.first
    min_distance = (matches.first.second - indices.first).abs
    matches.each do |match|
      indices.each do |b_i|
        distance = (match.second - b_i).abs
        if distance <= min_distance
          min_distance = distance
          closest_match = match
        end
      end
    end
    closest_match
  end

  def find_closest_match_bounds(word_lists, compare_words, distance_multiplier = 8)
    current_min_index = -1
    current_min_distance = Float::INFINITY
    word_lists.each_with_index do |word_list, index|
      next if word_list.blank?
      word_list.each do |word|
        next unless word.present?
        compare_words.each do |compare_word|
          distance = word.distance_to(compare_word)
          next unless distance < current_min_distance && close_enough?(word, compare_word, distance, distance_multiplier) # rubocop:disable Layout/LineLength
          current_min_distance = distance
          current_min_index = index
        end
      end
    end
    current_min_index
  end

  def close_enough?(word1, word2, distance, distance_multiplier)
    return distance < distance_multiplier * word1.font_height && word1.intersects_vertically?(word2) if word2.above?(word1) # rubocop:disable Layout/LineLength
    return distance < distance_multiplier * word1.font_width && word1.intersects_horizontally?(word2) if word2.left?(word1) # rubocop:disable Layout/LineLength
    false
  end

  def close_partial_match?(word_lists, compare_words); end

  def parse_address_str(str)
    return unless str.present?
    str = str.gsub(/,|US(A)?|United States( of America)?/i, '').strip
    adr = StreetAddress::US.parse(str)
    adr.as_json.merge('street_address' => adr.line1) if adr.present?
  end

  # to do: consolidate blacklist_words and blacklist_regex
  def name_and_multiline_address(vision_document, regex, blacklist_words = [], options = {})
    blacklist_regex = options.fetch(:blacklist_regex, nil)

    possible_addresses = build_name_and_address(vision_document, regex)
    return unless possible_addresses.present?
    addresses = possible_addresses.map { |address| address.compact.reverse!.map(&:text) }
    addresses.delete_if { |address| blacklist_words.any? { |word| address.join(' ').downcase.split.include?(word) } }
    addresses.delete_if { |address| address.join(' ').match?(blacklist_regex) } if blacklist_regex.present?
    possible_name_and_addresses = addresses.select { |address| address.first.match?(regex) || address.size == 1 }
    return [possible_name_and_addresses] if possible_name_and_addresses.size == 1
    possible_name_and_addresses = possible_name_and_addresses.select { |w| w.first.gsub(/[^a-z1-9\s-]/i, '').gsub(/\s\s/, ' ').upcase.match?(regex) } # rubocop:disable Layout/LineLength
    possible_name_and_addresses = possible_name_and_addresses.map { |w| [w.first.gsub(/[^a-z1-9\s-]/i, '').gsub(/\s\s/, ' ').upcase.match(regex)[:employer]] + w[1..] } # rubocop:disable Layout/LineLength
    name_choices = possible_name_and_addresses.map(&:first).uniq
    name = name_choices.first if name_choices.size == 1
    address = possible_name_and_addresses.first[1..] if name_choices.size == 1
    return unless address.present?
    [name, address]
  end

  def build_address_from_section(vision_document, bound)
    words = vision_document.sorted_grouped_words.select { |w| bound.contains_centroid?(w) }.sort_by(&:min_y)
    text = words.map(&:text).join(', ')
    addresses = text.scan(address_regex).map { |m| m.compact.join(' ') }
    addresses.map { |ad| GeocodeHelper.geocode(ad) }
  end

  def build_address(vision_document, options = {})
    loose = options.fetch(:loose, false)

    matches = state_zip_words(vision_document)
    matches = loose_state_zip_words(vision_document) if matches.blank? && loose
    matches = single_letter_state_zip_words(vision_document) if matches.blank? && loose
    return [] unless matches.present?
    buyer_words = [context[:buyer][:first_name], context[:buyer][:last_name]].join(' ').tr(',', '').split
    full_address = []
    matches.each do |initial_match|
      lines = []
      bottom_line = find_and_sort_words_on_the_same_line(initial_match, all_words(vision_document))
      lines.push(bottom_line)
      min_x, max_x = bottom_line.minmax_x
      next_line = keep_finding_words_vertically(vision_document, bottom_line, min_x: min_x, max_x: max_x)
      while next_line.present? && (next_line.text != lines[-1].text) && !complete_address?(lines)
        break if lines.size >= 5
        break if buyer_words.any? { |word| next_line.match?(/#{word}/i) }
        lines.push(next_line)
        new_min_x, new_max_x = next_line.minmax_x
        min_x = [min_x, new_min_x].min
        max_x = [max_x, new_max_x].max
        next_line = keep_finding_words_vertically(vision_document, next_line, min_x: min_x, max_x: max_x)
      end
      full_address.push(lines)
    end
    full_address
  end

  def combine_address_bounds(addr_words)
    words = addr_words.sort_by(&:min_y)
    VisionPackage::VisionWord.factory('text' => construct_phrase(words.map(&:text)), 'bounds' => combine_bounds(words))
  end

  def confident_address_str?(vision_document, str)
    confident_geocoded_address?(vision_document, GeocodeHelper.geocode(str))
  end

  def confident_geocoded_address?(vision_document, geocoded)
    addr = geocoded.full_address.gsub(/, USA|, United States/, '').split
    return false unless addr.present?
    return false if addr.first.match?(/\d+/) && addr.join(' ').match?(/PO Box/i)
    return false unless addr.first.starts_with?('P') || addr.first.match?(/\d+/)
    text = vision_document.ocr_text.squish
    return false unless addr.select { |part| text.match?(/#{part}/i) }.count.fdiv(addr.count) >= 0.6
    addr.count >= 5
  end

  def build_name_and_address(vision_document, regex)
    matches = state_zip_words(vision_document)
    return unless matches.present?
    full_address = []
    matches.each do |initial_match|
      lines = []
      bottom_line = find_and_sort_words_on_the_same_line(initial_match, all_words(vision_document))
      lines.push(bottom_line)
      next_line = keep_finding_words_vertically(vision_document, bottom_line)
      while next_line.present? && (next_line.text != lines[-1].text) && !complete_address?(lines)
        lines.push(next_line)
        next_line = keep_finding_words_vertically(vision_document, next_line)
      end
      if next_line.present?
        lines.push(next_line)
        # check if line above by chance ends with one of the endings to just be safe
        next_line = keep_finding_words_vertically(vision_document, next_line)
        lines.push(next_line) if next_line.present? && next_line.match?(regex)
      end
      full_address.push(lines)
    end
    full_address
  end

  def complete_address?(lines)
    lines.reverse.map(&:text).join(' ').match?(address_regex)
  end

  def state_name_from_loose_abbreviation(abb)
    LOOSE_ALL_STATE_NAMES.each do |key, value|
      return ALL_STATE_NAMES[key] if value.include?(abb)
    end
    nil
  end

  def state_abbreviation_from_name(name)
    name = name.to_s
    return name.upcase if STATE_ABBREVIATIONS.include?(name.upcase)
    ALL_STATE_NAMES[name.titleize.to_sym]
  end

  def fix_loose_state_zip_words(words)
    results = []
    words.each do |w|
      LOOSE_STATE_ABBREVIATIONS.each do |abb|
        state_abbrev = " #{abb} "
        next unless w[:corrected_text].include?(state_abbrev)
        state_name = state_name_from_loose_abbreviation(state_abbrev.strip)
        next if state_name.blank?
        state_name = " #{state_name} "
        w[:corrected_text].sub!(state_abbrev, state_name)
        results << w
      end
    end
    results
  end

  def loose_state_zip_words(vision_document)
    words = vision_document.combined_words&.select { |word| word.match?(STATE_ZIP_LOOSE_REGEX) }
    return fix_loose_state_zip_words(words) if words.present?
    words = vision_document.find_all_ocr_words_by_regex(STATE_ZIP_REGEX, vision_document.grouped_words)
    words = words&.sort_by { |w| [w.min_y, w.min_x] }
    return words.grep_v(STATE_ZIP_BLACKLIST_REGEX) if words.present?
    words = vision_document.find_all_ocr_words_by_regex(STATE_ZIP_LOOSE_REGEX, vision_document.grouped_words) if words.blank? # rubocop:disable Layout/LineLength
    words = fix_loose_state_zip_words(words)
    words = words&.sort_by { |w| [w.min_y, w.min_x] }
    words.grep_v(STATE_ZIP_BLACKLIST_REGEX)
  end

  def state_zip_words(vision_document)
    vision_document.combined_words&.select { |word| word.match?(STATE_ZIP_REGEX) }
  end

  def single_letter_state_zip_words(vision_document)
    # use zip regex to fetch address bottom_line
    words = vision_document.combined_words&.select { |word| word.match?(STRICT_ZIP_REGEX) }
    words.concat(vision_document.find_all_ocr_words_by_regex(STRICT_ZIP_REGEX, vision_document.grouped_words))
    words.each do |w|
      bottom_line, = find_words_to_left_with_words(w, all_words(vision_document))
      next if bottom_line.match?(STATE_ZIP_BLACKLIST_REGEX)
      next if bottom_line.match?(/^[0-9]*$/)
      return [bottom_line]
    end
    []
  end

  # this function will find words that are on the same line and then sort through them to make sure
  # that it is not picking up garbage
  def find_and_sort_words_on_the_same_line(match, all_words, direction = 'both', options = {})
    ignore_distance = options.fetch(:ignore_distance, false)

    all_words_on_line = words_connected_on_slope(match, all_words)
    # remove words that are in the match
    all_words_on_line.delete_if { |word| word.text.upcase.in?(match.text.upcase) }
    # find average character space
    avg_space_per_char = average_character_width(match)
    # get all the words that are close to the match
    keep_finding_words_horizontally(match, all_words_on_line, avg_space_per_char, direction, ignore_distance: ignore_distance) # rubocop:disable Layout/LineLength
  end

  def find_words_to_left_with_words(match, all_words, options = {})
    ignore_distance = options.fetch(:ignore_distance, false)

    all_words_on_line = words_connected_on_slope(match, all_words)
    words_to_left = all_words_on_line.reject { |word| word.min_x > match.max_x }
    all_words_on_line.delete_if { |word| word.text.in?(match.text) }
    avg_space_per_char = average_character_width(match)
    merged_word = keep_finding_words_horizontally(match, all_words_on_line, avg_space_per_char, 'left', ignore_distance: ignore_distance) # rubocop:disable Layout/LineLength
    [merged_word, words_to_left]
  end

  def average_character_width(match)
    match.char_width
  end

  def keep_finding_words_vertically(vision_document, horizontal_match, options = {})
    min_x = options.fetch(:min_x, nil)
    max_x = options.fetch(:max_x, nil)

    polygon = construct_polygon_around(horizontal_match, min_x: min_x, max_x: max_x)
    return unless polygon.present?
    words_found = words_contained_in_polygon(polygon, all_words(vision_document))
    return unless words_found.present?
    above_word = find_lowest_word_in_polygon(words_found)
    find_and_sort_words_on_the_same_line(above_word, all_words(vision_document))
  end

  def find_words_above(vision_document, horizontal_match)
    polygon = construct_polygon_around(horizontal_match)
    return unless polygon.present?
    words_found = words_contained_in_polygon(polygon, all_words(vision_document))
    return unless words_found.present?
    max_y = words_found.map(&:max_y).max
    last_row_words = sort_words_row_first(words_found.select { |a| a.max_y >= max_y - 5 }, true)
    VisionPackage::VisionWord.factory('text' => last_row_words.map(&:text).join(' '), 'bounds' => combine_bounds(last_row_words)) # rubocop:disable Layout/LineLength
  end

  def construct_polygon_around(horizontal_match, options = {})
    min_x = options.fetch(:min_x, nil)
    max_x = options.fetch(:max_x, nil)

    bounds_of_match = horizontal_match['bounds']
    return unless bounds_of_match.present?
    ymin, ymax = increase_bounds_height(bounds_of_match)
    xmin, xmax = bounds_of_match.minmax_x
    draw_polygon([xmin, min_x || xmin].min, [xmax, max_x || xmax].max, ymin, ymax)
  end

  def find_lowest_word_in_polygon(words_found)
    words_found&.max_by(&:max_y)
  end

  def increase_bounds_height(bounds)
    return unless bounds.present?
    min_y, max_y = bounds.minmax_y
    font_height = bounds.font_height
    [min_y - (font_height * 1.5).to_i, max_y - font_height]
  end

  def get_min_max_bounds(bounds)
    [bounds.map { |x| x.values[0] }.minmax, bounds.map { |x| x.values[1] }.minmax].flatten
  end

  def draw_polygon(xmin, xmax, ymin, ymax)
    Polygon.new([Point(xmin, ymin),
                 Point(xmin, ymax),
                 Point(xmax, ymax),
                 Point(xmax, ymin)])
  end

  def keep_finding_words_horizontally(match, all_words_on_line, average_character_space, direction = 'both', options = {}) # rubocop:disable Layout/LineLength
    ignore_distance = options.fetch(:ignore_distance, false)

    case direction
    when 'right'
      words_to_the_right = words_to_specified_direction(match, all_words_on_line, direction)
      append_words_in_direction(match, words_to_the_right, nil, average_character_space, direction, ignore_distance: ignore_distance) # rubocop:disable Layout/LineLength
    when 'left'
      words_to_the_left = words_to_specified_direction(match, all_words_on_line, direction)
      append_words_in_direction(match, nil, words_to_the_left, average_character_space, direction, ignore_distance: ignore_distance) # rubocop:disable Layout/LineLength
    else
      words_to_the_right = words_to_specified_direction(match, all_words_on_line, 'right')
      words_to_the_left = words_to_specified_direction(match, all_words_on_line, 'left')
      valid_words_to_the_right = append_words_in_direction(match, words_to_the_right, words_to_the_left, average_character_space, 'right', ignore_distance: ignore_distance) # rubocop:disable Layout/LineLength
      append_words_in_direction(valid_words_to_the_right, words_to_the_right, words_to_the_left, average_character_space, 'left', ignore_distance: ignore_distance) # rubocop:disable Layout/LineLength
    end
  end

  def words_to_specified_direction(match, all_words_on_line, direction)
    op = direction == 'right' ? '>=' : '<='
    all_words_on_line.select { |word| word.min_x.send(op, match.min_x) }
  end

  def append_words_in_direction(match, words_to_the_right, words_to_the_left, avg_space_per_char, direction, options = {}) # rubocop:disable Layout/LineLength
    ignore_distance = options.fetch(:ignore_distance, false)

    largest_word = match
    if direction == 'right'
      largest_word_right_end = largest_word.max_x
      closest_word = words_to_the_right.min_by(&:min_x)
      while closest_word.present? && (ignore_distance || closest_word.min_x - largest_word_right_end < 5 * avg_space_per_char) # rubocop:disable Layout/LineLength
        bounds = combine_bounds([largest_word, closest_word])
        text = [largest_word.text, closest_word.text].join(' ')
        largest_word = VisionPackage::VisionWord.factory('text' => text, 'bounds' => bounds)
        largest_word_right_end = largest_word.max_x
        words_to_the_right.delete_if { |word| word.text.in? closest_word.text }
        closest_word = words_to_the_right.min_by(&:min_x)
      end
    else
      largest_word_left_end = largest_word.min_x
      closest_word = words_to_the_left.max_by(&:max_x)
      while closest_word.present? && (ignore_distance || largest_word_left_end - closest_word.max_x < 5 * avg_space_per_char)  # rubocop:disable Layout/LineLength
        bounds = combine_bounds([closest_word, largest_word])
        text = [closest_word.text, largest_word.text].join(' ')
        largest_word = VisionPackage::VisionWord.factory('text' => text, 'bounds' => bounds)
        largest_word_left_end = largest_word.min_x
        words_to_the_left.delete_if { |word| word.text.in? closest_word.text }
        closest_word = words_to_the_left.max_by(&:max_x)
      end
    end
    largest_word
  end

  def all_words(vision_document)
    vision_document.merged_data&.dig('document_text', 'words').present? ? vision_document.merged_data&.dig('document_text', 'words') : vision_document.merged_data&.dig('text', 'words') # rubocop:disable Layout/LineLength
  end
end
