# rubocop:disable Layout/LineLength

module VisionPackage
  module RegexConstants
    # TODO: Convert these date regexes to use named captures [#153832001]
    YY ||= /(?<year>[0-9][0-9OB])/i.freeze
    YYYY ||= /(?<year>(?:19|20)[0-9OB]{2})/i.freeze
    UNCAPTURED_MM_STRICT ||= /[1][O0-2]|[O0][1-9BS]/i.freeze
    MM_STRICT ||= /(?<month>#{UNCAPTURED_MM_STRICT})/i.freeze
    UNCAPTURED_MM ||= /[1][O0-2]|[O0]?[1-9BS]/i.freeze
    MM ||= /(?<month>#{UNCAPTURED_MM})/i.freeze
    MONTH ||= /(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)/i.freeze
    CAPTURE_MONTH ||= /(?<month>#{MONTH})/i.freeze
    UNCAPTURED_DD_STRICT ||= /[1-2O][0-9OB]|[3][0-1O]|[O0][1-9B]/i.freeze
    DD_STRICT ||= /(?<day>#{UNCAPTURED_DD_STRICT})/i.freeze
    DD ||= /(?:[1-2O][0-9OB]|[3][0-1O]|[O0]?[1-9B])/i.freeze
    CAPTURE_DD ||= /(?<day>#{DD})/i.freeze
    DATE_SEPARATOR_STRICT ||= /[:\/\-]/.freeze
    DATE_SEPARATOR ||= /[17.:\/\-]/.freeze
    DATE_START ||= /(?:^|\b|\D)/.freeze
    DATE_FINISHED ||= /[_.:]/.freeze
    NANV_TEXT ||= /not_available|not_visible|notPresent/i.freeze

    MD ||= /#{MM}#{DATE_SEPARATOR_STRICT} ?#{CAPTURE_DD}(?:(?:#{DATE_SEPARATOR_STRICT}| ))/.freeze
    MMDD ||= /#{MM_STRICT}#{DATE_SEPARATOR}? ?#{DD_STRICT}(?:(?:#{DATE_SEPARATOR}| ))?/.freeze
    MMDD_FULL ||= Regexp.union(MD, MMDD)

    MMDDYYYY ||= /#{DATE_START}#{MMDD_FULL}#{YYYY}#{DATE_FINISHED}?\b/.freeze

    YYYYMMDD ||= /#{DATE_START}#{YYYY}#{DATE_SEPARATOR}?#{MM}#{DATE_SEPARATOR}#{CAPTURE_DD}#{DATE_FINISHED}?\b/.freeze
    YYMMDD ||= /#{DATE_START}#{YY}#{DATE_SEPARATOR}?#{MM}#{DATE_SEPARATOR}?#{CAPTURE_DD}#{DATE_FINISHED}?\b/.freeze

    # FIXME: "January 2013" =~ RegexConstants::MONTHDDYY => 0
    MMYY ||= /#{MM}#{DATE_SEPARATOR_STRICT}#{YY}/i.freeze
    MONTHDDYY ||= /(#{CAPTURE_MONTH}[\-,.\s]*#{CAPTURE_DD}[,.\s\-\/]+(?<year>(?:19|20)?[']?[0-9][0-9OB)]))/.freeze
    DDMONTHYY ||= /(?:^|\b|\D|1)(#{CAPTURE_DD}[\-,\s]*#{CAPTURE_MONTH}[\-,\s]*(?<year>(?:19|20)?[0-9][0-9OB]))\b/.freeze

    UNCAPTURED_MONTHDDYY ||= /(#{MONTH}[\-,.\s]*#{DD}[,.\s\-\/]*(?:(?:19|20)?[']?[0-9][0-9OB)]))/.freeze
    UNCAPTURED_DDMONTHYY ||= /#{DATE_START}(#{DD}[\-,\s]*#{MONTH}[\-,\s]*(?:(?:19|20)?[0-9][0-9OB]))\b/.freeze

    MMDDYY ||= /#{DATE_START}#{MMDD_FULL}#{YY}#{DATE_FINISHED}?\b/.freeze

    ALL_DATE ||= Regexp.union(MMDDYYYY, YYYYMMDD, MONTHDDYY, DDMONTHYY, MMDDYY).freeze
    HRS_AMOUNTS ||= /\b\d{1,3}(?:\.|\:|\,)(?:\d{2,4})(?: hrs)?/i.freeze
    HRS_NO_DECIMAL ||= /(?<=^|\s)[1-9][0-9]{0,2}(?=\s|$)/.freeze
    HRS_ONE_DECIMAL ||= /\b\d{1,3}(?:\.|\:|\,)(?:\d{1,4})(?: hrs)?/i.freeze
    HRS_LOOSE ||= /(?:^#{HRS_AMOUNTS}$)|(?:^#{HRS_NO_DECIMAL}$)|#{HRS_ONE_DECIMAL}/.freeze
    HRS_RATE ||= /\b\d{1,3}(?:\.|\:)\d{4,6}\b/.freeze

    MMDDYYYY_TEXT ||= /(?:\b)?[O01]?[0-9][\.\/\-]? ?[0123]?[0-9]#{DATE_SEPARATOR}?(?:19|20)[0-9][0-9](?:\b)?/.freeze

    # DO NOT add this to ALL_DATE
    CAPTURE_MMDD ||= /\b([01]?[0-9])#{DATE_SEPARATOR_STRICT}([0123]?[0-9])\b/.freeze
    UNCAPTURED_MD ||= /#{UNCAPTURED_MM}#{DATE_SEPARATOR_STRICT} ?#{DD}#{DATE_FINISHED}?/.freeze
    MONTHDD ||= /\b(?:#{MONTH})[\-,.\s]*(?:[0123]?[0-9])\b/.freeze
    DDMONTH ||= /\b(?:[0123]?[0-9])[\-,.\s]*(?:#{MONTH})\b/.freeze

    PARTIAL_DATE_REGEX ||= Regexp.union(UNCAPTURED_MD, MONTHDD, DDMONTH).freeze
    PARTIAL_DATE_WORD ||= /(?:^#{Regexp.union(UNCAPTURED_MD, MONTHDD, DDMONTH)}$)/.freeze
    # Bharath: If you intend to change any of these partial date regexes, please talk to me
    PERCENT ||= /(?:\d+(?:\.\d+)?(?: )?%)/i.freeze
    CO_APP ||= /co(?:\-)?applicant/i.freeze

    # 11-17 Jan 17 (this type of date range is used in Military LES)
    LES_DATE_RANGE ||= /(?<=^|\s)(\d{1,2}-\d{1,2}\s#{MONTH}\s\d{2})(?=\s|$)/i.freeze
    CAPTURE_LES_DATE_RANGE ||= /(?<begin_day>\d{1,2})-(?<end_day>\d{1,2})\s(?<month>#{MONTH})\s(?<year>\d{2})/i.freeze
    CAPTURE_LES_DATE_WITH_SPACES_RANGE ||= /(?<begin_day>\d{1,2})\s?-\s?(?<end_day>\d{1,2})\s(?<month>#{MONTH})\s(?<year>\d{2})/i.freeze

    SPACE ||= /(?:\s)?/.freeze
    SSN_SEPARATOR ||= /[\-|\_| |1\t]/.freeze
    CAPTURE_FULL_SSN ||= /((?:\d){3})#{SPACE}#{SSN_SEPARATOR}#{SPACE}((?:\d){2})#{SPACE}#{SSN_SEPARATOR}#{SPACE}((?:\d){4})\b/.freeze
    FULL_SSN ||= /((?:\d){3}#{SPACE}#{SSN_SEPARATOR}#{SPACE}(?:\d){2}#{SPACE}#{SSN_SEPARATOR}#{SPACE}(?:\d){4})\b/.freeze
    PARTIAL_SSN ||= /((?:(?:\*|x|c|\#)#{SPACE}){1,3}#{SPACE}#{SSN_SEPARATOR}#{SPACE}(?:(?:\*|x|c|\#)#{SPACE}){1,2}#{SPACE}#{SSN_SEPARATOR}#{SPACE}\d{4})/i.freeze
    ALL_X_SSN ||= /((?:(?:\*|x|c|\#)#{SPACE}){1,3}#{SPACE}#{SSN_SEPARATOR}#{SPACE}(?:(?:\*|x|c|\#)#{SPACE}){1,2}#{SPACE}#{SSN_SEPARATOR}#{SPACE}(?:(?:\*|x|c|\#)#{SPACE}){4})/i.freeze
    SSN ||= Regexp.union(FULL_SSN, PARTIAL_SSN).freeze
    YTD ||= /\b(?:y[\-.]?t[\-.]?d|To Date|Y[eo]ar[\- ]?To[\- ]?Da[rt][eo])(?: (?:Amount|Total(?:s)?|Amt|dollars|Earnings))?\b/i.freeze
    YTD_GROSS ||= /gross ytd (earnings|eamings)?|ytd gross|ytd (earnings|eamings)/i.freeze
    INCORRECT_YTD_WORDS ||= /deductions|dedicatans|adjusted|shift|net|fica|taxable|medicare|\bss\b/i.freeze
    INCORRECT_RIGHT_YTD_WORDS ||= /salary/i.freeze
    REGULAR_PAY_LABELS ||= /pay period t[ao]tal hours|sal pd|sal|reg pay|regular|regular hours|straight[-\s]?time(?: pay)?|time entry wag(?:es)?|hourly regular|staf wages?|hourly wages?|regular pay|reg hrly|h[r|o]ly wages?|actual pay|hr reg|(?:regular )?base pay|basic pay|rg wages?|attendance hrs|Hospitality Labor|base ern|daily rate|driver pay|orientation|train{1,2}ing|time(?:\s)*entry|hourwage|transport|hour[lt]y|regular\s?-?salary|reg|hourly\s?regular\s?(rate)?/i.freeze
    PAY_BEGIN_DATE_LABELS ||= /(?:pay|pe(?:ri|n)od|week) (?:start(?:ing)?|begi(?:b)?n(?:ning)?)[ ]?(?:dt|date)?|PPE|(?:start(?:ing)?|begi(?:b)?n(?:ning)?) pe(?:ri|n)od|(?:start(?:ing)?|begi(?:b)?n(?:ning)?)[ ]?(?:dt|date)|reporting(?: )?(?:period|per)(?: )?beginning(?: )?(?::)?/i.freeze
    PAY_END_DATE_LABELS ||= /(?:pay|pe(?:ri|n)od|week) (?:b|e)nd(?:ing|ed)?[ ]?(?:dt|date)?|PPE|(?:b|e)nd(?:ing|ed)? pe(?:ri|n)od|(?:b|e)nd(?:ing|ed)?[ ]?(?:dt|date)|reporting(?: )?(?:period|per)(?: )?ending(?: )?(?::)?/i.freeze
    PAY_DATE_LABELS ||= /(?:check|chk|pay(?:ment)?|paid|deposit) (?:da[tl]e|da[tl]a|through|thru):?/i.freeze
    EMPLOYEE_NUMBER_LABELS ||= /(?:employee|emp|ee) (?:number|no|#)/i.freeze
    CHECK_NUMBER_LABELS ||= /(?:check|chk|ck) (?:number|no|#)?/i.freeze
    PAY_PERIOD ||= /(?:pay|current)?(?: )?(?:period|per)(?: )?(?::)?/i.freeze
    PAYSTUB_MEDICARE_TAX_LABELS ||= %r{FED MED/EE|Medicare Employee|Employee Medicare|fica - medicare|f\.i\.c\.a\./medicare|\bficamed|f\.?i\.?c\.?m}i.freeze
    PAYSTUB_SOC_SEC_TAX_LABELS ||= %r{Social Security Employee(?: Tax)?|\Afica\z|soc sec(?! ?[:#])|fica(?: )?-(?: )?oasdi|\b[oq]asdi\b|social secur(?:ity)?(?: tax)?|fed oasdi/ee|\bss(?: tax)?|f.i.c.a}i.freeze
    PAYSTUB_MEDICARE_TAX_BLACK_LIST ||= /Medicare (?:.{0,4}\s)?taxable wages|Medicare Employee Add[li] Tax|med prod plus|employer medicare/i.freeze
    NOT_AN_EMPLOYER_NAME ||= /amount|time off|sick|net pay|taxable|pre ?tax|post ?tax|hours?|taxes/i.freeze
    PAY_PERIOD_RANGE_LABEL ||= /(?:pay(?:roll)?|date) ?(?:period|range)|period Beg\/End/i.freeze

    HRS_RATE_LABELS ||= /rate|hourly\s?rate/i.freeze
    HRS_WORKED_LABELS ||= /hours?|qty|units?|hrs\/units|hrs|quantity/i.freeze
    VACATION_LABELS ||= /(?:personal )?time off|paid? time of[f|t]|time of|personal?|pers leave|p\. ?[tl]\. ?o|\bhoway\b|halidar-field|\bpol\b|halidny|acation|ersonal|p\. ?lo|paid tue of|b-day holiday|paid date oil|hi-fid|plo mgmt|\b[rp]a[il]d ?ti[mn][aeco]|time off|pa[il]d ti[cm]e?|holid|horld\b|oliday\b|h[aeo]llday|holday|(?:hol|vac)pay|(?:h[oa]l|vac)\b|(?:h[oa]l|vac)[kh]rly|ho!|\bp[ti]o|leave w\/pay|annual leave|vactn|v[ao]catio|vaca|v(?:a|is)ca[lt][li]on|vikation|leave|ppl|ho(l|i)|p.?\s?t.?\s?o.?|vaca?tion/i.freeze
    SICK_LABELS ||= /(sick|\bsck\b|stok pay|\bsio|medical visit|illness)/i.freeze
    SHIFT_LABELS ||= /shi[fi]t|shft/i.freeze
    STRICT_OVERTIME_LABELS ||= /doubl[ec](?:[\s-]?time)?|(?:triple|dbl) time|\bo.?time|\b.?vert(?:im|h)e\b|[0o]vert?i?me?|\b[ocq]v[ae]r? ?[tl][ai](?:[a-z]{1,2}[aeo])?\b|\bo[a-z][\s\/]?time|\bovt(?! ?(?:hrs|rate))\b|o.?t ?earning|(?:holida?y|ot) prem(?:ium)?|(?:weekend|premium|holiday.?) (?:worked|o.?t\b)|Hol ?W[oi]?rk|\bsunday\b|wkly ot\b|work(?:ing)? holiday|\b(?:overt|overno)\b|\bo\.t\.?\b|\b1\.5x\b|(?:o\/?t|hol[a-z]day) ?1?\.5\b|h[il]yot|time\sand\s(?:1\/?|v)2|time & half|\bo\/?t\s?[1-9]\b|[o0]\/time|additional day|ovrtime|ot-/i.freeze
    OVERTIME_LABELS ||= /#{STRICT_OVERTIME_LABELS}|\b(?:ct|oi)[^a-z]?\b|\b[0o][n\/]?t(?!her)\b|^dt|ot.pay|\b[0o]v|[0o]\/t|shift diff|prem(?:ium|i)?\b|hourlyot|@1.5/i.freeze
    COMMISSION_LABELS ||= /commission/i.freeze
    REGULAR_LABELS ||= /\b(#{RegexConstants::REGULAR_PAY_LABELS}|regis pay|Guaranteed Hours|comp time|keyular|work hours|retpay|hr sch|rece|logging|[rp][aeo][pg]u[il]ar?|recular|fieguiar|Flegu|hr(?:l)?ywage|cont[r]?act|regularpay|regwages|regpay|reg|hourly|salaried|salary?|wages|daily|attendance|earned|rg|base|r[ae].. ?hours\b)|productv|full\s?time|reg\s?shift/i.freeze
    BENEFIT_LABELS ||= /\bflex (?:base)? ?credit\b/i.freeze
    BASE_LABELS ||= /#{VisionPackage::RegexConstants::REGULAR_PAY_LABELS}|#{VisionPackage::RegexConstants::VACATION_LABELS}|#{VisionPackage::RegexConstants::SICK_LABELS}|reg|regular|hou(r|s)(l|t)y|orientation|regular\spay|reg\spay|regular\shours|base\spay(?:\srate)?|regular\searnings|\brg|lar\b|earnings/i.freeze

    NEGATIVE_SIGN ||= /(?:\-)/.freeze
    DOLLAR_SIGN_OPTIONS ||= /(?:-[ ]?(?:S|\$)|(?:S|\$)[ ]?-|(?:S|\$))/i.freeze
    COMMA_SEPARATED_CURRENCY_BODY ||= /[1-9]\d{0,2} ?(?:[,;\.]?[ ]?\d{3})?/.freeze
    NO_COMMA_CURRENCY_BODY ||= /[1-9]\d+/.freeze
    CURRENCY_BODY ||= /(?:#{COMMA_SEPARATED_CURRENCY_BODY}|#{NO_COMMA_CURRENCY_BODY}|[0-9])/.freeze
    CURRENCY_CENTS ||= /(?:[:,\.\_ -]\s?\d{2})/.freeze
    CURRENCY_FINISHED ||= /(?!\S*\d)/.freeze
    CURRENCY_ALT_1 ||= /(?:\()?#{DOLLAR_SIGN_OPTIONS}#{CURRENCY_BODY}#{CURRENCY_CENTS}?(?:\))?#{CURRENCY_FINISHED}/.freeze
    CURRENCY_ALT_2 ||= /(?:#{NEGATIVE_SIGN}(?: )?|\()?#{CURRENCY_BODY}#{CURRENCY_CENTS}(?:#{NEGATIVE_SIGN}|\))?#{CURRENCY_FINISHED}(?! ?ho?u?rs)/.freeze
    CURRENCY ||= /(?<=^|\D)#{CURRENCY_ALT_1}|#{CURRENCY_ALT_2}/.freeze
    CURRENCY_WORD ||= /(?:^#{CURRENCY_ALT_1}$)|(?:^#{CURRENCY_ALT_2}$)/.freeze

    DOLLAR_SIGN_OPTIONS_CLEAN ||= /(?:-[ ]?(?:\$)|(?:\$)[ ]?-|(?:\$))/i.freeze
    COMMA_SEPARATED_CURRENCY_BODY_CLEAN ||= /[1-9]\d{0,2}(?:[,]?\d{3})?/.freeze
    CURRENCY_BODY_CLEAN ||= /(?:#{COMMA_SEPARATED_CURRENCY_BODY_CLEAN}|#{NO_COMMA_CURRENCY_BODY}|[0-9])/.freeze
    CURRENCY_CENTS_CLEAN ||= /(?:[.]\d{2})/.freeze
    CURRENCY_ALT_1_CLEAN ||= /(?:\()?#{DOLLAR_SIGN_OPTIONS_CLEAN}#{CURRENCY_BODY_CLEAN}#{CURRENCY_CENTS_CLEAN}?(?:\))?#{CURRENCY_FINISHED}/.freeze
    CURRENCY_ALT_2_CLEAN ||= /(?:#{NEGATIVE_SIGN}(?: )?|\()?#{CURRENCY_BODY_CLEAN}#{CURRENCY_CENTS_CLEAN}(?:#{NEGATIVE_SIGN}|\))?#{CURRENCY_FINISHED}(?! ?hours)/.freeze
    CURRENCY_WORD_CLEAN ||= /(?:^#{CURRENCY_ALT_1_CLEAN}$)|(?:^#{CURRENCY_ALT_2_CLEAN}$)/.freeze

    ODOMETER ||= /(?<=^|\s|\/|\()#{CURRENCY_BODY}#{CURRENCY_FINISHED}/.freeze
    ODOMETER_WORD ||= /^#{CURRENCY_BODY}#{CURRENCY_FINISHED}$/.freeze

    PERCENTAGE_VALUE ||= /\b\d+\.\d+(?=\s?%)\b/.freeze
    # Regex Reference https://rgxdb.com/r/61PVCR9B
    UNCAPTURED_VIN_NUMBER ||= /[A-HJ-NPR-Z\d]{3}[A-HJ-NPR-Z\d]{5}[\dX][A-HJ-NPR-Z\d][A-HJ-NPR-Z\d][A-HJ-NPR-Z\d]{6}/i.freeze
    VIN_NUMBER ||= /(?<wmi>[A-HJ-NPR-Z\d]{3})(?<vds>[A-HJ-NPR-Z\d]{5})(?<check>[\dX])(?<vis>(?<year>[A-HJ-NPR-Z\d])(?<plant>[A-HJ-NPR-Z\d])(?<seq>[A-HJ-NPR-Z\d]{6}))/.freeze
    UNCAPTURED_LOOSE_VIN_NUMBER ||= /[A-HIJ-NOPR-Z\dØ]{3}[A-HIJ-NOPR-Z\dØ]{5}[\dXØS][A-HIJ-NOPR-Z\dØ][A-HIJ-NOPR-Z\dØ][A-HIJ-NOPR-Z\dØ]{6}/i.freeze
    LOOSE_VIN_NUMBER ||= /(?<wmi>[A-HIJ-NOPR-Z\dØ]{3})(?<vds>[A-HIJ-NOPR-Z\dØ]{5})(?<check>[\dXØS])(?<vis>(?<year>[A-HIJ-NOPR-Z\dØ])(?<plant>[A-HIJ-NOPR-Z\dØ])(?<seq>[A-HIJ-NOPR-Z\dØ]{6}))/.freeze
    ODOMETER ||= /(?<=^|\s)(#{CURRENCY_BODY})(?=\s|$)/.freeze
    NUM_REQUIRED_REFERENCES ||= /\Anum_required_references/.freeze

    UTILITY_BILL_DUE_DATE_LABELS ||= /pay(?:ment)? (?:by|due)|pay before|(?:payment)? ?due date|delinquent after|(?:total)?(?: amount)? due (?:by|on)|(?:current )?charges due(?: by)?|your payment by|due on or before|date due|new charges due|total amount you owe by|pay by|no later than|due by|past due after|amount due (?:by)?|payments must be received by/i.freeze
    UTILITY_BILL_DUE_DATE_LABELS_WITH_DOLLAR ||= /(?:pay|for) #{CURRENCY} (?:by|on)/i.freeze
    UTILITY_BILL_ISSUE_DATE_LABELS ||= /(?:b[il][lj]l(?:ing)?|bh|statement|invoice|notice|mailing|letter| ?issue){1,2} dates?\:?|date (?:prepared|mai?led)|end of billing period|(?:account summary|balance) as of|balance at bi(?:ll|b)ing on|issued|date bill prepared|bill prepared on|bill creation date\:?|date printed|electric bill|date\-mailed|mailed on/i.freeze
    SERVICE_ADDRESS_LABEL ||= /(?:service|statement) (?:addr(?:ess)|at|for)/i.freeze
    HOURLY_LABELS ||= /[dot] hrs|regular pay|hourly rate|regular earnings|hourly wage|hourly overtime/i.freeze
    TIPS_REGEX ||= /\b((?<!and )(?:cash)? ?(?:imp)?ti[pq]s?(?! and| are| credit)|tlps|gratuity)\b/i.freeze
    BONUS_REGEX ||= /\b((?<!type: )f?bonu?s?h?s?(?:-annual|-direct)?(?:[a-z]{1,2})?(?! election| die|-)|b[au]nus|ponus|donus|safety\.? (bon|barns)?|borrus|bonuses|bomus|borus|monthly bonus?\b)|att(?:e)nd(?:ance)? b(?:o)?n(?:u)?s|bermus|(?<!non-discretionary) incen[tl]ive|(?<!ssion) incentive|\b(crtbonus|merit|merchaward)\b|award of thanks|performance pay|\bprize\b|(?<!total )rew(?:a)?rd|\b(incetv|inct(?:v)?|incnt|saf ?bon|(?:sales )?incenti? ?(?:pay)?|sales incerit|(?<!t\.o\. )awa[ar]ds?(?! for|-?pto))\b|recogn(?:ition)?|\b[a-z]+awa[ar]d\b|\bqtr bns\b/i.freeze
    COMMISSION_REGEX ||= /\b((?<!non-|joint |see )com(?:m)?ission?s?(?! associates)|comm(?![\.-]|unications?|ercial)[ie]?(?! inc))\b|comsn|sale(s?)|commisi?on|\b(compassion|retail com|corrurission|conlission|[a-z]+-nondiscretionary courmisica|curumission|comreg|comot|ceminisslon)\b|piecework|\b(cornission|salecom|commesi)\b/i.freeze

    # Insurance ID Card regex
    POLICY_NUMBER_LABELS ||= /(?:temporary )?(?:policy|binder)\s*(?:number|no\.?|#|)/i.freeze
    SIMPLE_NUMERIC_PN_FORMAT ||= /(?:[0-9](?: |-)?){7,20}/.freeze
    GEICO_PN_FORMAT ||= /[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}/.freeze
    STATE_FARM_PN_FORMAT ||= /[0-9]{3} [0-9]{4}-[a-z][0-9]{2}-[0-9]{2}[0-9a-z]?/i.freeze
    USAA_PN_FORAMT ||= /\d{5} \d{2} \d{2}[a-z] \d{4} \d/i.freeze
    MERCURY_PN_FORMAT ||= /\d{4}[ -]\d{2}[ -]\d{4}[ -]?\d{5}/.freeze
    ALLIANCE_PN_FORMAT ||= /MIL[0-9]{7}/i.freeze
    MIXED_PN_FORMAT ||= /[0-9 \-]*[a-z]{1,4}[0-9 \-]{7,13}/i.freeze
    ALPHANUMERIC_PN_FORMAT ||= /\b(?=[\w\-]*[0-9][\w\-]*\b)(?=[\w\-]*[A-Z][\w\-]*\b)(?=[\w\-]*[\-][\w\-]*\b)[\w\-]{11,}\b/.freeze
    STRICT_PN_REGEX ||= Regexp.union(GEICO_PN_FORMAT, STATE_FARM_PN_FORMAT, ALLIANCE_PN_FORMAT, ALPHANUMERIC_PN_FORMAT, USAA_PN_FORAMT, MERCURY_PN_FORMAT).freeze
    POLICY_NUMBER_VALUES ||= Regexp.union(SIMPLE_NUMERIC_PN_FORMAT, GEICO_PN_FORMAT, STATE_FARM_PN_FORMAT, ALLIANCE_PN_FORMAT, MIXED_PN_FORMAT, USAA_PN_FORAMT, MERCURY_PN_FORMAT).freeze

    PHONE_NUMBER ||= /\(?[2-9][0-8]\d\)?\s?\-?\|?\s?[2-9]\d{2}\s?\-?\s?\d{4}/.freeze
    TOLL_PHONE_NUMBER ||= /1?\-?(?:800|877|866|888|900|500|600|210)\-[A-Z0-9\-]{7,10}/.freeze

    CURRENT_PERIOD ||= /\b(?:current|t?his|the) (?:stmt|per[i|l]od|check|amt)(?: \([\$5]\))?|(?:cur-pay)|haul pay/i.freeze
    CURRENT_GROSS ||= /\bgross wages\b/i.freeze
    EARNING ||= /earnings|eamings|earrings|barnings|eurnings/i.freeze
    EARNING_NO_STATEMENT ||= /(#{EARNING})(?! ?statement)/i.freeze
    EARNING_WAGES ||= /#{EARNING}|pay|wages/i.freeze
    GROSS ||= /gr[oa][gs][se]?/i.freeze
    # FIXME: Merge overlapping regex
    GARNISHMENTS_STRICT_REGEX ||= /gum\ssugant|[gc]amsupp?Child|Ga[nm][a-z]{5,7}Child|orders-child|Garnishment Fee|c[uh]ld\ssup|[cg]a(?:rn|m)ish|support\spayment|c\/support|emp\/child|family\ssupp|ganzishmen|[cg]hil?d\s(?:sup(?:port|t)?|sppt|care)|child\s?curr|support\sorder/i.freeze
    GARNISHMENTS ||= /#{GARNISHMENTS_STRICT_REGEX}|\bgarn\b|alimony|spous|chsupp|chdsup|[CG]ar?[a-z]is(?:h|ti)m(?:en)?t?|childspt|^support(?! [a-z])|child?suppt?|chldsup|grnsh/i.freeze
    LOANS_STRICT_REGEX ||= /40[1b] ?\(?[1kx]\)?[^a-z]{0,3}(?:l[a-z]{1,3}n|[li][na]|Repaymt)|l[a-z]{1,2}an payment|a\/r loan|403\s?\(b\)\s?lo[am]n|(?:emp|stud(?:ent)?)\s?(?:ln\b|loan)/i.freeze
    LOANS ||= /#{LOANS_STRICT_REGEX}|\bl[oc][aá][nr]/i.freeze
    PRE_TAX_DEDUCTIONS ||= /medical\sfsa|(med|insurance)?\spre\stax|pre\stax|Dental\s125|medpt/i.freeze
    DEDUCTIONS ||= /#{GARNISHMENTS}|#{LOANS}|uniforms|401 ?(\(|-)?k\)?|403b|K401|pension loanro what|(life|term|acc(ident)?|iii|std) ins(urance)?|roth|disability deduction|(long|short) term dis(ability)?|stock|^pers$|court orders?|medical\sfsa|(med|insurance)?\spre\stax/i.freeze
    DEDUCTIONS_LOOSE ||= /group term life|(health|dental|vision|accident|medical) ?(insurance)?|fitness|pre[\s\-]?tax|\bpretx/i.freeze

    # form_1040
    TOTAL_INCOME ||= /(?:youtotal|[lit]o[lt]al) inco[rm]e/i.freeze
    CURRENCY_LOOSE_DIGITS_WITH_PUNCTUATION ||= /\-?\(?\d{1,3}[.,] ?\d{3}[.,]?\)?/.freeze
    # combine digits and dash, like -100. This format is common in form_1040
    CURRENCY_LOOSE_DIGITS ||= /\-\d{2,3}[.,]?/.freeze
    CURRENCY_LOOSE ||= Regexp.union(CURRENCY_LOOSE_DIGITS_WITH_PUNCTUATION, CURRENCY_LOOSE_DIGITS).freeze
    NET_PROFIT ||= /n[oe]t profit o[rd] ?(?:\(loss\))?|s(?:ubt)?ract line 30 from line 29/i.freeze
    NET_PROFIT_TEXT ||= /n[oe]t profit o[rd] ?(?:\(loss\))?[.]?/i.freeze
    NET_PROFIT_FALLBACK ||= /net profit(?:\.|\ssubtract)/i.freeze
    DEPRECIATION ||= /deprec[li]ation and[. ]section/i.freeze
    SCHEDULE_C_EZ ||= /schedule[ ]?c-ez/i.freeze

    # bank statement
    SUMMARY_PREFIX ||= /balance|activity|account|statement|checking|unt|relationship|membership|spend account/i.freeze
    SUMMARY_1 ||= /#{SUMMARY_PREFIX}\ssummary/i.freeze
    SUMMARY_2 ||= /checking account/i.freeze
    SUMMARY_3 ||= /summary of (?:account|transactions)/i.freeze
    CHASE_TOTAL_CHECKING ||= /chase total checking/i.freeze
    CONSOLIDATED_STATEMENT ||= /accounts\ssummary|(?:combined|consolidated)\s(?:balance|statement)|summary\sof(?:\syour)?(?:\sdeposit)?\s(?:accounts)/i.freeze
    SAVINGS_SUMMARY ||= /savings? summary/i.freeze
    SUMMARY ||= Regexp.union(SUMMARY_1, SUMMARY_2, SUMMARY_3, CHASE_TOTAL_CHECKING).freeze
    ALL_SUMMARY ||= Regexp.union(SUMMARY_1, SUMMARY_2, SUMMARY_3, CHASE_TOTAL_CHECKING, SAVINGS_SUMMARY).freeze
    SUMMARY_LOOSE ||= /summary/i.freeze
    MULTILINE_DEPOSIT_TOP_LINE ||= /^d(?:e|o)posits and(?: credits)?$/i.freeze
    MULTILINE_DEPOSIT_BOTTOM_LINE ||= /(?:o|a)ther additions|amount/i.freeze
    DEPOSIT ||= /(?:addition|depos(?:h|it)(?! accounts?|s totaling)|credit)(?:ed|s)?/i.freeze
    DEPOSIT_MOST_RELATED_LABELS ||= /(?:total )?deposi[l|t]s and (?:other)?\s?(?:additions|credits)|total deposits(?:\s)*(?:\/|&)(?:\s)*credits/i.freeze
    DEPOSIT_MORE_RELATED_LABELS ||= /\d{1,3}\.?\s?(?:total)?\s?deposits(?:\/credits)?/i.freeze
    DEPOSIT_LABEL_1 ||= /prepaid card deposits/i.freeze
    DEPOSIT_LABEL_2 ||= /deposits.?\s?\/?(?: misc )?&?\s?(?:credits|additions)/i.freeze
    DEPOSIT_LABEL_3 ||= /(?:^\d{1,2})? ?deposits (?:and|&)\s?(?:other)?\s?(?:credits|addit[.|i]ons)/i.freeze
    DEPOSIT_LABEL_4 ||= /total\s(?:credits|additions)/i.freeze
    DEPOSIT_LABEL_5 ||= /depo(?:si?ts|raids)\/(?:additions|credits)/i.freeze
    DEPOSIT_LABEL_6 ||= /credit\(s\) this period/i.freeze
    SPANISH_DEPOSIT_LABEL ||= /dep[ó|o]sitos\s?y?\/?\s?adiciones/i.freeze
    DEPOSIT_RELATED_LABELS ||= Regexp.union(DEPOSIT_LABEL_1, DEPOSIT_LABEL_2, DEPOSIT_LABEL_3, DEPOSIT_LABEL_4, DEPOSIT_LABEL_5, DEPOSIT_LABEL_6, SPANISH_DEPOSIT_LABEL).freeze
    DEPOSIT_LOOSE ||= /^depos[i|l][t|l]s$|payments\/credits|(de)?posits\s?\/\s?credits|deposits\s?&\s?cred[i|l][t|l]s|^electronic\s?deposits$|credits\s?(\(\+\))?|(\(\+\))?\s?credits\s?and\s?adjustments|you\s?deposited,\s?credited\s?or\s?transferred\s?in|depositos\/adiciones|additions|deposits\/additions/i.freeze
    BEGINNING_BALANCE_LABELS ||= /(?:beginning|previous|opening|starting|ginning)\s(?:balance|statement)(?:\son)?|ending\sbalance\slast\sstatement|beginning\sbalance\sthis\speriod|balance\sforward\sfrom|balance\s?last\s?statement|forward|previous\s?balance\s?as\s?of|previous\s?statement\s?balance\s?as\s?of|last\s?statement|saldo\sinicial/i.freeze
    ENDING_BALANCE_LABELS ||= /(?:ending|current|closing|new)\s(?:balance|statement)(?:\son)?(?!\slast)|ending\sbalance\sthis\s(?:statement|period)|new\s?balance\s?as\s?of|balance\s?this\s?statement|current\s?statement\s?balance\s?as\s?of|this\s?statement|saldo\sfinal/i.freeze
    CUSTOM_BALANCE_LABELS ||= /CHECKING\s?ACCOUNT/.freeze
    BANK_TOTAL ||= /totals|total\s?subtracted\/?added/i.freeze
    BANK_HEADER_DEPOISTS_1 ||= /deposits.?\/?\s?(?:credits|additions)/i.freeze
    BANK_HEADER_DEPOSITS_2 ||= /amou(?:n|ri)t\s?added/i.freeze
    BANK_HEADER_DEPOSITS_3 ||= /deposit(?:s)?(?: )?\/(?: )?credit(?:s)?(?: )?(?:activity)?/i.freeze
    BANK_HEADER_DEPOSITS_LOOSE ||= /credits|additions/i.freeze
    SSI_LABELS ||= /[s\$][s\$]a treas|xxsoc sec|xxsocial security|[s\$][s\$]i treas|supp sec/i.freeze
    BANK_HEADER_DEPOSITS ||= Regexp.union(BANK_HEADER_DEPOISTS_1, BANK_HEADER_DEPOSITS_2, BANK_HEADER_DEPOSITS_3).freeze
    DEPOSIT_LABELS ||= /(?:amount added)|deposits|credit(?:s)?|additions/i.freeze
    DEPOSITS_POSTING_DATE ||= /(?:electronic )?deposits(?: \(continued\))?(?:\s)posting date|other credits(?:\s)posting date/i.freeze
    DEPOSITS_AND_ADDITIONS ||= /d(?:e|o)posits (?:and|\&)(?: other)? (?:additions[a-z]?|credit(?:s)?)|deposit(?: )\/(?: )credit activity|deposits,(?: )credits and interest|deposits and other credits|deposits(?: )?\/(?: )?credits|other deposits|fee refunds/i.freeze
    TOTAL_DEPOSITS_AND_ADDITIONS ||= /tota(?:l)? deposits (?:and|\&)(?: other)? additions|tota(?:l)? card deposits (?:and|\&) credits|total deposits(?:\s)*(?:\/|&)(?:\s)*credits|subtotal/i.freeze
    PAYMENTS_POSTING_DATE ||= /(?:electronic )?payments(?: \(continued\))?(?:\s)posting date/i.freeze
    WITHDRAWAL_AND_SUBTRACTIONS ||= /withdrawals (?:and|\&)(?: other)? (?:subtractions|purchases|debit(?:s)?)|atm (?:and|\&) debit card withdrawals|card withdrawals|checks paid|checks and other deductions|deductions/i.freeze
    TOTAL_WITHDRAWAL_AND_SUBTRACTIONS ||= /total(?: )?withdrawals (?:and|\&)(?: other)? (?:subtractions|debit(?:s)?)|total atm (?:and|\&) debit card withdrawals/i.freeze
    ALL_DEPOSITS_AND_ADDITIONS ||= Regexp.union(TOTAL_DEPOSITS_AND_ADDITIONS, DEPOSITS_AND_ADDITIONS).freeze
    TRANSACTION_HISTORY ||= /transaction (?:history|detail|by date)/i.freeze
    TRANSFER_PAYMENT_FROM ||= /(?:transfer|payment) from|(?:tfr|pmt|pmnt) frm/i.freeze
    TRANSFER_TO_CHECKING ||= /transfer to (?:checking|chk)/i.freeze
    ACH_PAYMENT ||= /ACH (?:pay|pmt)/i.freeze
    PURCHASE_RETURN ||= /purchase retu(?:rn|m)/i.freeze
    BLANK_PAGE ||= /page (?:has been )?(?:int.+)?left (?:int.+)?blank/i.freeze
    CONTINUED_PAGE ||= /continued/i.freeze
    TRANSACTION_FEES_SUMMARY ||= /(?:account)? transaction fees? summary/i.freeze
    RANDOM_BANK_PAGE_TEXT ||= /bank deposit account|statement of account|(?:federal\s)?credit\s?union|performance select statement|spending account statement|important account information|member\sfdic/i.freeze
    SPANISH_REGEX_BASIC ||= /(usted\sy wells fargo|Resumen de actividata|transacciones|resumen de cuenta|depositos y adiciones)/i.freeze
    ACCOUNT_TOTAL ||= /total\sdeposit\saccounts?|total\sassets|total\sbalances?|total(?:\scurrent)?\svalue/i.freeze
    TOTALS ||= /totals?/i.freeze
    CHECKING ||= /checkings?/i.freeze
    SAVINGS ||= /savings?/i.freeze
    DEPOSITS_BLACKLIST ||= /withdraw|withdra?wa?l(?:s)?|purchase|(?:b|d)?eginning balance|payment to|to (?:checking|saving)|service fee|fee|standard monthly|(?<!p)en(d|c)ing|dividends|previous balance|ending balance|(?:closing|daily) balance|number of days|charge|sent to|opening balance|debit card purchase|Resulting Balance|transfer (?:debit )?to|debit (.*)electronic check|chargeback|recurring debit card|web pmt|debit card payment|electronic pmt-web|serial no.|standard time|page/i.freeze
    ZELLE_PAYMENT_FROM ||= /ze(?:l|i)(?:l|i)e (?:from|transfer)/i.freeze

    # Account number
    BANK_ACCOUNT_NUMBER_STRICT ||= /\d{1,5}(?: |\-)\d{2,8}(?: |\-)\d{1,4}(?: |\-)?(?:\d{2,4})?|\d{6,17}|(?:x|\*){3,10}\d{4,7}/i.freeze
    BANK_ACCOUNT_NUMBER_LOOSE ||= /(?:x|\*|\d)(?:[\-\d x\*]{5,})\d/i.freeze
    BANK_ACCOUNT_NUMBER_BADOCR ||= Regexp.union(BANK_ACCOUNT_NUMBER_STRICT, BANK_ACCOUNT_NUMBER_LOOSE).freeze
    BANK_ACCOUNT_NUMBER_LABEL ||= /(?<!and )(?:primary )?account (?:number|\#|no)|bb(?:\&)t fundamentals|business (?:value|checking)/i.freeze
    BANK_ACCOUNT_NUMBER_LABEL_VALUE ||= /account:\s*[x\d]+/i.freeze

    # SSI award letter
    SSI_BENEFITS ||= /(?:((?:benefit|amount) \(?before (?:any )?deductions?\)? i[sa])[\.\s]*)/i.freeze
    SSI_INCOME ||= /(?:Supplemental Security\.? Inco[mr]e payment [1i][9se]\.?[\.\s]*)/i.freeze
    SSI_DEDUCTIONS ||= /(?:we deduct for Medicare Medical Insurance is)/i.freeze
    SSI_NET_AMOUNT ||= /(?:after we take any other deductions\, you will receive)/i.freeze
    SSI_TRAIL_REGEX ||= /social|security|administration|office/i.freeze
    SSI_HEAD_REGEX ||= /social|security|administration|securing/i.freeze
    VALID_SSI_WORDS ||= /social|security|administration|beneficiary|supplemental|security|\sssi|benefits|office|go direct|godirect/i.freeze

    # Govt ID
    PASSPORT ||= /pas(?:s|a)port?i?(?:e)?/i.freeze
    CONSULAR ||= /consul(?:ar|ado)?|matricula/i.freeze
    MILITARY_ID ||= /veterans affairs|department of defense|uniformed services/i.freeze
    STATE_ID ||= /(?:i)?de(?:n)?ti(?:fication|nondriver)?/i.freeze
    DL_STRICT ||= /driver(?:\'s)? license/i.freeze
    DL ||= /driver(?:\'s)?|license|operator|motorcycle|motor vehicle/i.freeze
    DL_BLACKLIST ||= /nondriver|not a driver(?:\'s)? license/i.freeze
    NOT_DL ||= /edit profile|register to vote|driving status|mydmv|frequently asked questions/i.freeze
    GREEN_CARD ||= /permanent resident|resident since/i.freeze
    UNITED_STATES_PASSPORT ||= /united states/i.freeze
    NON_US_PASSPORT ||= /mexicanos|canada/i.freeze

    EXPIRATION_DATE ||= /Ex(?:p|e)?|Expires|Expiration Date/i.freeze
    DOB ||= /dob|date of birth/i.freeze

    # Utility Bill
    UTILITY_BILL_SPECIFIC_WORDS ||= /electric|gas|meter|energy|tv|water|gas|power|trash/i.freeze
    COMMON_UTILITY_BILL_WORDS ||= /electric|charges|service(?: )?address|service(?: )?addr|meter|usage|energy|account(?: )?number|internet|tv|water|gas|power|pwr|trash|wtr|due(?: )?date|amount(?: )?due|total(?: )due|service(?: )?at|remittance|past(?: )?due|pay(?: )?by|billing(?: )?date|account(?: )?#|billing(?: )period|invoice/i.freeze
    COMMON_COMPANY_NAMES ||= /spectrum|at&t|atnt|cox|verizon|tmobile|xfinity|comcast|sprint/i.freeze
    # Multi Paystub Verification
    PAYSTUB_SINGLE_OCCURRENCE ||= Regexp.union(REGULAR_PAY_LABELS, PAY_PERIOD, EMPLOYEE_NUMBER_LABELS, PAY_BEGIN_DATE_LABELS, CHECK_NUMBER_LABELS, PAY_END_DATE_LABELS, PAY_DATE_LABELS, PAYSTUB_MEDICARE_TAX_LABELS, PAYSTUB_SOC_SEC_TAX_LABELS, /(?:#{RegexConstants::GROSS}|total) (?:#{RegexConstants::EARNING_WAGES})/i, CURRENT_PERIOD, CURRENT_GROSS, GARNISHMENTS, PHONE_NUMBER)
    CONTINUED_PAYSTUB ||= /(?:page)? ?(?<page_num>\d) ?of ?\d/i.freeze
    CONTINUED_PAYSTUB_PAGE ||= /(pa(y|v)|pay ?stub) (for )?period|(start|end|check) date|pa(y|v) (da(t|l)e|type|week|start)|period end(ing)?|(employee|advice) (no|number|id|name)|ssn|soc(ial|\.) sec(urity|\.) (no|number|employee)|advice|week ending|emp ?\#|for period|payroll from|time ea(rn|m)ed/i.freeze
    USPS_REGEX ||= /USPS Employee Earnings(?: Statement)?|USPS RETIREMENT/i.freeze
    PAYSTUB_DD_RECEIPT ||= /non ?-? ?negotiable|endorse (h|m)ere/i.freeze

    WORK_NUMBER_REPORT ||= /Work Number|\bFCRA\b|Current Year Total Compensation|Total Length of Service|Projected Annual Income|Most Recent Hire Date/i.freeze
    HIRE_DATE ||= /most recent (?:hire|start) date:/i.freeze
    EMPLOYER_NAME ||= /employer\:/i.freeze
    STAFF_ONE_REPORT ||= /staff ?one.?com|Employment data|Original Date of Hire|Work Email|Payroll Inquiry/i.freeze
    EMPLOYMENT_VERIFICATION ||= /verification services|Verified On|Verification Type|Tracking Number|official verification/i.freeze

    # form 1040
    INDIVIDUAL_TAX_RETURN_START ||= /\b(?:u|j)[\.\,]?s[\.\,]? (?:individual|nonresident alien) income tax retu(?:rn|m)?\b/i.freeze
    INDIVIDUAL_TAX_RETURN_START_YEAR ||= /(^|[\s|]|return)(?<year>20\d{2})\s/i.freeze
    AMENDED_TAX_RETURN_START ||= /\bamended #{INDIVIDUAL_TAX_RETURN_START}\b/i.freeze

    # ATPI
    INSURANCE_PROVIDER_LABELS ||= /insurance company and agent|insurance company|ins. co./i.freeze

    EFFECTIVE_DATE ||= /(?<!original )(?<!manufacturer's )((agreement|contract|plan|converage) )?(?<!original )(?<!vehicle )(?<!car )(effectiv(e|a)|application|purchase|start) date|(?<!original )date of purchase|(?:contract|option) sale date/i.freeze # rubocop:disable Layout/LineLength
    # GAP WAIVER CONTRACT
    GAP_FORM_NUMBER ||= /Form No(?: )?\:|LZX|WIC|TNPP|TVPP|INDP|GCMFV|CHPA|SGF|DDS\-|TASA|DLP/i.freeze
    GAP_PREMIUM ||= /charge|purchase the gap|purchase price|addendum (cost|purch)/i.freeze
    TERM ||= /(?<!pp )(contract |agreement )?term(s)?( in| of)?( months| cont(r)?act)?|cont(r)?act months|t(e|o)rm/i.freeze
    GAP_PROVIDER_GMAC ||= /gmac|universal warranty|ally (?:auto)?(?:-)?(?:gap)?|all(?: )?state/i.freeze
    GAP_PROVIDER_JMA ||= /JIM MORAN&ASSOCIATES, INC|(J|U)M(?:&)?(?: )?A(?: group)?(?: gap)?/i.freeze
    GAP_PROVIDER_SAFEGUARD ||= /SAFE-GUARD PRODUCTS INTERNATIONAL|safe(?:-)?(?:guard)?(?:(?: |-)?gap)?|honda(?: care)?(?: gap)?/i.freeze
    GAP_PROVIDER_PDS ||= /PREMIER DEALER SERVICES|pds (?:gap)?/i.freeze
    GAP_PROVIDER_IAS ||= /Innovative Aftermarket Systems|isa(?: gap)?|ias(?: gap)?/i.freeze
    GAP_PROVIDER_US ||= /united states warranty corp|us gap/i.freeze
    GAP_PROVIDER_AWS ||= /Automotive warranty services|aws|ans/i.freeze
    GAP_PROVIDER_EXPRESS ||= /Express Systems Inc|Express (?:Auto)?(?: )?(?:Gap)?/i.freeze
    GAP_PROVIDER_CSCI ||= /Customer Service Center Inc|csci/i.freeze
    GAP_PROVIDER_NAS ||= /Nation Motor Club (?:llc)?|nas (nationwide|gap)|nsp(?: gap)?/i.freeze
    GAP_PROVIDER_AHIS ||= /American Heritage(?: Insurance)?(?: Services)?|ahis(?: gap)?(?: addendum)?|((?:5 )?star|allstate)(?: gap)?/i.freeze
    GAP_PROVIDER_TMIS ||= /Toyota Motor Insurance Services|tmis/i.freeze
    GAP_PROVIDER_APPI ||= /Advanced Protection Products International Inc|appi(?: online)?(?: gap)?|global trust/i.freeze
    GAP_PROVIDER_NORMAN ||= /Norman and Company Inc|Norman & Co|Classic(?: track)?(?: gap)?/i.freeze
    GAP_PROVIDER_CARCO ||= /Comprehensive Auto Resources Company Inc|car(?: )?co/i.freeze
    GAP_PROVIDER_LDS ||= /loss deficiency surety insurance company|lds (?:gap)?/i.freeze
    GAP_PROVIDER_AMERICAN ||= /american auto guardian|maagi gap guardian|AutoGuard Guaranteed Asset Protection/i.freeze
    GAP_PROVIDER_TASA ||= /tasa|debt guardian/i.freeze
    GAP_PROVIDER_EQUITY ||= /financial gap|equityprotect/i.freeze
    GAP_PROVIDER_SOUTHWEST ||= /southwest reinsure inc|first auto(?:motive)? gap/i.freeze

    # VSC
    VSC_PROVIDER_AUL ||= /(Secure ?One|A\.?[ ]?U\.?[ ]?L\.?(?: Corp)?|Marathon Administrative)/i.freeze
    VSC_PREMIUM ||= /(service|agreement|contract|VSC|care|total) +(purcha(s|b)e |selling |sale )?(term&)?(price|charge)|individual protection plans/i.freeze
    VSC_TERM_LABEL ||= /Te(?:r(?:m|n)|nn)s in (?:Miles|Months) ?(?:\:|\.)|(?:(?:Contract|Total) )?(?:Te(?:r(?:m|n)|nn)|Plan) (?:Mile(?:age|s)|Months?)|Coverage (?:Mile(?:age|s)|Months?)|days from warranty|Miles from Current|Months from Service|Additional Miles/i.freeze
    FORM_NUMBER ||= /\bfo(?:m|r|rm)(?: num(?:ber)?)?/i

    # RISC
    CURRENCY_WORD_LOOSE ||= /(?:#{VisionPackage::RegexConstants::DOLLAR_SIGN_OPTIONS}?)(?:[\s\_])?#{VisionPackage::RegexConstants::CURRENCY_BODY} ?#{VisionPackage::RegexConstants::CURRENCY_CENTS}/.freeze # rubocop:disable Layout/LineLength
    VSC_ITEMIZATION_LABEL ||= /for (?:serv(?:ice)?|svc) (?:cont(?:ract)?)/i.freeze
    RISC_E_CONTRACT_FORM_NUMBER ||= /[A-Z]{2}\-103/i.freeze
    RISC_NUMBER_PAYMENTS ||= /(?:No.|Number) of payments/i.freeze
  end
end

# rubocop:enable Layout/LineLength
