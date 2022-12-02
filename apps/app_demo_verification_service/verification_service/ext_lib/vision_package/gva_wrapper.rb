# need to figure out what to do with these
require_relative 'document_ocr_analysis'
require_relative 'refinements/hash_extensions'
require_relative 'regex_constants'
require_relative '../address_helper'

# Informed Wrapper for Google Vision API
module VisionPackage
  class GvaWrapper
    extend DocumentOcrAnalysis
    using VisionPackage::Refinements::HashExtensions

    # to detect the content starts from a new row, test two points' min and max value separately
    # rather than simple point2's min greater than point1's max
    MAX_DIFF ||= 10
    MIN_DIFF ||= 5
    # when the symbol is a dot, its x value is not consecutive to its previous character even there is no space
    EXTRA_PIXEL_FOR_DOT ||= 6

    DOCUMENT_TEXT ||= 'document_text'.freeze
    TEXT ||= 'text'.freeze
    COMBINED_WORDS ||= 'combined_words'.freeze
    COMBINED_INDICES ||= 'combined_indices'.freeze
    GROUPED_WORDS ||= 'grouped_words'.freeze

    CATEGORIES ||= [DOCUMENT_TEXT, TEXT].freeze

    LABELS ||= 'label'.freeze
    DOLLAR_AMOUNTS ||= 'dollar'.freeze
    DATES ||= 'date'.freeze
    SSN ||= 'ssn'.freeze
    POLICY_NUMBERS ||= 'policy_number'.freeze
    PHONE_NUMBERS ||= 'phone_number'.freeze
    ACCOUNT_NUMBER ||= 'account_number'.freeze
    HOURS ||= 'hour'.freeze
    HOURLY_RATE ||= 'hourly_rate'.freeze
    BLANK_SSN ||= 'blank_ssn'.freeze
    PERCENT ||= 'percent'.freeze
    VIN ||= 'vin'.freeze
    ODOMETER ||= 'odometer'.freeze
    PARTIAL_DATE ||= 'partial_date'.freeze

    COMBINED_CATEGORIES ||= [LABELS, DOLLAR_AMOUNTS, DATES, SSN, POLICY_NUMBERS, PHONE_NUMBERS, ACCOUNT_NUMBER, HOURS, HOURLY_RATE, BLANK_SSN, PERCENT, VIN, ODOMETER, PARTIAL_DATE].freeze # rubocop:disable Layout/LineLength
    # Not a huge fan of this, but we don't add document types very often
    INCOME_DOC_TYPES ||= %i[paystub bank_statement ssi_award_letter military_les military_ras job_offer_letter
                            student_financial_aid child_support_court_order foster_care disability_insurance_letter
                            passive_income trust_letter annuity_statement rental_property w2 va_award_letter
                            alimony_court_order employment_verification_form employment_verification_letter form_1040
                            form_1099 canceled_check].freeze

    DEALER_DOC_TYPES ||= %i[credit_application credit_approval credit_score_disclosure_exception bookout_sheet
                            retail_installment_sales_contract closed_end_motor_vehicle_lease_with_arbitration_provision
                            authorization_to_release_payoff_information acknowledgement_of_rewritten_contract
                            cosigner_notice title_application power_of_attorney_retail power_of_attorney_trade_in
                            odometer_disclosure_statement_retail risk_based_pricing_notice buyers_order lease_order
                            foreign_language_acknowledgement kbb_bookout_sheet factory_invoice nada_bookout_sheet
                            gap_waiver_contract vehicle_service_contract credit_life_disability_contract
                            closed_end_motor_vehicle_lease buy_program purchase_order credit_report gap_binder
                            contract_cancellation_option guarantee_of_title report_of_sale negative_equity_form
                            electronic_consent cancellation_agreement odometer_disclosure_statement_lease
                            maintenance_plan anti_theft appearance_plan windshield_protection key_replacement
                            paintless_dent_repair bundled_product tire_wheel_plan added_products_services
                            pre_contract_disclosure gap_disclosure gap_liability_notice].freeze

    SHARED_COMBINATION_REGEXES ||= {
      currency:     [
        { source: DOCUMENT_TEXT, regex: RegexConstants::CURRENCY, delimiters: '$,;.: ()-', category: DOLLAR_AMOUNTS }
      ],
      exp_date:     [
        { source: TEXT, regex: RegexConstants::MMDDYYYY_TEXT, delimiters: '', category: DATES },
        { source: TEXT, regex: RegexConstants::MONTHDDYY, delimiters: '', category: DATES }
      ],
      income:       [
        { source: DOCUMENT_TEXT, regex: RegexConstants::HIRE_DATE, delimiters: ' :', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PAY_BEGIN_DATE_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PAY_END_DATE_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::YTD, delimiters: '-. ', category: LABELS },
        { source: TEXT, regex: RegexConstants::YTD, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /BASE PAY|PERIOD COVERED/i, delimiters: ' ', category: LABELS },
        # not exactly income specific, but there's a few military doc types so I think this should go here
        { source: DOCUMENT_TEXT, regex: /AIR FORCE/, delimiters: ' ', category: LABELS }
      ],
      full_ssn:     [
        { source: DOCUMENT_TEXT, regex: RegexConstants::FULL_SSN, delimiters: '-_ ', category: SSN }
      ],
      partial_ssn:  [
        { source: DOCUMENT_TEXT, regex: RegexConstants::PARTIAL_SSN, delimiters: '-_*# ', category: SSN }
      ],
      partial_date: [
        { source: DOCUMENT_TEXT, regex: RegexConstants::UNCAPTURED_MD, delimiters: '/._:, -', category: DATES },
        { source: DOCUMENT_TEXT, regex: RegexConstants::MONTHDD, delimiters: ',/ -', category: DATES },
        { source: DOCUMENT_TEXT, regex: RegexConstants::DDMONTH, delimiters: ',/ -', category: DATES }
      ],
      gap_waiver:   [
        { source: DOCUMENT_TEXT, regex: RegexConstants::GAP_FORM_NUMBER, delimiters: ' :', category: LABELS }
      ],
      vin:          [
        { source: DOCUMENT_TEXT, regex: RegexConstants::UNCAPTURED_VIN_NUMBER, delimiters: 'Ø', category: VIN },
        { source: DOCUMENT_TEXT, regex: RegexConstants::UNCAPTURED_LOOSE_VIN_NUMBER, delimiters: 'Ø', category: VIN }
      ],
      percent:      [
        { source: DOCUMENT_TEXT, regex: RegexConstants::PERCENT, delimiters: '. %', category: PERCENT }
      ],
      state_zip:    [
        { source: DOCUMENT_TEXT, regex: AddressHelper::STATE_ZIP_REGEX, delimiters: ', ' }
      ],
      odometer:     [
        { source: DOCUMENT_TEXT, regex: RegexConstants::ODOMETER, delimiters: ',;.: ', category: ODOMETER }
      ]
    }.freeze

    INCOME_TYPES ||= INCOME_DOC_TYPES.map do |type|
      type == :bank_statement ? { type.to_sym => %i[partial_date currency income] } : { type.to_sym => %i[full_ssn currency income partial_ssn] } # rubocop:disable Layout/LineLength
    end.reduce(&:merge).freeze

    DEALER_TYPES ||= DEALER_DOC_TYPES.map { |type| { type.to_sym => %i[percent partial_date currency vin state_zip odometer] } }.reduce(&:merge).freeze # rubocop:disable Layout/LineLength

    DOCUMENT_SHARED_MAP ||= INCOME_TYPES.merge(DEALER_TYPES).merge(
      utility_bill:         %i[currency],
      social_security_card: %i[full_ssn partial_ssn],
      driver_license_front: %i[exp_date],
      state_id:             %i[exp_date],
      military_id:          %i[exp_date],
      passport:             %i[exp_date],
      mexican_matriculas:   %i[exp_date],
      unknown:              %i[currency]
    ).freeze

    # rubocop:disable Layout/LineLength
    DOCUMENT_COMBINATION_REGEXES ||= {
      form_1040:                         [
        { source: DOCUMENT_TEXT, regex: /(Total Income|Adjusted Gross Income)/i, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /Your social security(?: number)?/i, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::TOTAL_INCOME, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::CURRENCY_LOOSE, delimiters: '$,.() -', category: DOLLAR_AMOUNTS },
        { source: TEXT, regex: RegexConstants::CURRENCY_LOOSE, delimiters: ' ', category: DOLLAR_AMOUNTS }
      ],
      credit_application:                [
        { source: DOCUMENT_TEXT, regex: RegexConstants::CO_APP, delimiters: ' ', category: LABELS }
      ],
      insurance_id_card:                 [
        { source: DOCUMENT_TEXT, regex: RegexConstants::POLICY_NUMBER_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::POLICY_NUMBER_VALUES, delimiters: ' -', category: POLICY_NUMBERS }
      ],
      employment_verification_letter:    [
        { source: DOCUMENT_TEXT, regex: RegexConstants::EMPLOYER_NAME, delimiters: ':', category: LABELS }
      ],
      paystub:                           [
        { source: DOCUMENT_TEXT, regex: RegexConstants::REGULAR_PAY_LABELS, delimiters: ' -', category: LABELS },
        { source: TEXT, regex: RegexConstants::CURRENCY, delimiters: '$,;.: ()-', category: DOLLAR_AMOUNTS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PAY_DATE_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::CHECK_NUMBER_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::EMPLOYEE_NUMBER_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PAYSTUB_MEDICARE_TAX_LABELS, delimiters: ' ./', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PAYSTUB_SOC_SEC_TAX_LABELS, delimiters: ' \n./-', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PAYSTUB_MEDICARE_TAX_BLACK_LIST, delimiters: ' ()',
          category: LABELS },
        { source: DOCUMENT_TEXT, regex: /(?:#{RegexConstants::GROSS}|total) (?:#{RegexConstants::EARNING_WAGES})/i,
          delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::YTD_GROSS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /gross ytd (#{RegexConstants::EARNING})?|ytd gross|ytd (#{RegexConstants::EARNING})|pay rate/i, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::CURRENT_PERIOD, delimiters: ' )(-', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::HRS_LOOSE, delimiters: '.:, ', category: HOURS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::HRS_RATE, delimiters: '.:', category: HOURLY_RATE },
        { source: DOCUMENT_TEXT, regex: RegexConstants::HOURLY_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /Medicare tax/i, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::CURRENT_GROSS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PAY_PERIOD, delimiters: ': ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PHONE_NUMBER, delimiters: ' ()/|-', category: PHONE_NUMBERS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::GARNISHMENTS, delimiters: ' /\n-', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::LOANS, delimiters: ' ()/\n-', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::ALL_DATE, delimiters: ',/ -', category: DATES },
        { source: DOCUMENT_TEXT, regex: RegexConstants::VACATION_LABELS, delimiters: ' ./!-', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::OVERTIME_LABELS, delimiters: ' ./&-', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::HRS_RATE_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::ALL_X_SSN, delimiters: ' _*#-', category: BLANK_SSN }
      ],
      bank_statement:                    [
        { source: DOCUMENT_TEXT, regex: RegexConstants::SUMMARY, delimiters: ' \n', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::TOTAL_DEPOSITS_AND_ADDITIONS, delimiters: ',/& ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::DEPOSIT_MOST_RELATED_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::DEPOSIT_MORE_RELATED_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::DEPOSIT_RELATED_LABELS, delimiters: './&ó \n', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::BANK_TOTAL, delimiters: '/ ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::BANK_HEADER_DEPOSITS, delimiters: '|!/ \n', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::DEPOSITS_POSTING_DATE, delimiters: ' \n()', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::DEPOSIT_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::TOTAL_WITHDRAWAL_AND_SUBTRACTIONS, delimiters: ',/ ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::WITHDRAWAL_AND_SUBTRACTIONS, delimiters: ',/ ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::DEPOSITS_AND_ADDITIONS, delimiters: ',/ ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::SSI_LABELS, delimiters: ' $', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::TRANSACTION_HISTORY, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::TRANSFER_PAYMENT_FROM, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::TRANSFER_TO_CHECKING, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::ACH_PAYMENT, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PURCHASE_RETURN, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::BANK_ACCOUNT_NUMBER_LABEL, delimiters: ' &#*', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::BANK_ACCOUNT_NUMBER_STRICT, delimiters: ' -', category: ACCOUNT_NUMBER },
        { source: DOCUMENT_TEXT, regex: RegexConstants::BANK_ACCOUNT_NUMBER_LOOSE, delimiters: ' -', category: ACCOUNT_NUMBER },
        { source: DOCUMENT_TEXT, regex: RegexConstants::BEGINNING_BALANCE_LABELS, delimiters: ' \n', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::ENDING_BALANCE_LABELS, delimiters: ' \n', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::ACCOUNT_TOTAL, delimiters: ' \n', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::CONSOLIDATED_STATEMENT, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::PAYMENTS_POSTING_DATE, delimiters: ' \n()', category: LABELS }
      ],
      retail_installment_sales_contract: [
        { source: DOCUMENT_TEXT, regex: RegexConstants::ODOMETER, delimiters: ',. ' },
        { source: DOCUMENT_TEXT, regex: /(business or commercial)|(Business, commercial or agricultural)/i,
          delimiters: ', ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /Seller Name and Address/i, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /N(?:I|\/)?A/, delimiters: '/' },
        { source: DOCUMENT_TEXT, regex: RegexConstants::CURRENCY_WORD_LOOSE, delimiters: '$,.() _-' },
        { source: DOCUMENT_TEXT, regex: RegexConstants::VSC_ITEMIZATION_LABEL, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /service\s?contract(?:.{0,2}paid\s?to)?/i, delimiters: '$,.() -', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::RISC_NUMBER_PAYMENTS, delimiters: '. ', category: LABELS }
      ],
      utility_bill:                      [
        { source: DOCUMENT_TEXT, regex: /pay(?:ment)? by/i, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /(Previous Amount|Past Due|Previous Bill|(Remaining )?Previous Balance)/i,
          delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /(Balance Forward|(Previous )?Unpaid (Balance|Amount))/i, delimiters: ' ',
          category: LABELS },
        { source: DOCUMENT_TEXT, regex: /(Payment Received|Previous Bill minus Payment)/i, delimiters: ' ',
          category: LABELS },
        { source: DOCUMENT_TEXT, regex: /(Amount Due|Total (Now |Amount )?Due|Total amount you owe|Current Charges)/i,
          delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::UTILITY_BILL_DUE_DATE_LABELS, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::UTILITY_BILL_ISSUE_DATE_LABELS, delimiters: ': -', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::SERVICE_ADDRESS_LABEL, delimiters: ' ', category: LABELS }
      ],
      w2:                                [
        { source: DOCUMENT_TEXT, regex: /(?:Federal|Local|State) income tax/i, delimiters: ' ', category: LABELS },
        { source: DOCUMENT_TEXT, regex: /(?:Medicare|Local|State|Social security) wages/i, delimiters: ' ,',
          category: LABELS },
        { source: DOCUMENT_TEXT, regex: /(?:Wages,? tips,? other)/i, delimiters: ' .,', category: LABELS }
      ],
      military_les:                      [
        { source: DOCUMENT_TEXT, regex: RegexConstants::LES_DATE_RANGE, delimiters: '- ', category: DATES }
      ],
      atpi:                              [
        { source: DOCUMENT_TEXT, regex: RegexConstants::INSURANCE_PROVIDER_LABELS, delimiters: ' .', category: LABELS }
      ],
      ssi_award_letter:                  [
        { source: DOCUMENT_TEXT, regex: RegexConstants::SSI_BENEFITS, delimiters: ' .,()', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::SSI_INCOME, delimiters: ' .,', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::SSI_DEDUCTIONS, delimiters: ' .,', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::SSI_NET_AMOUNT, delimiters: ' .,', category: LABELS }
      ],
      driver_license_front:              [
        { source: DOCUMENT_TEXT, regex: RegexConstants::EXPIRATION_DATE, delimiters: ' ', category: LABELS },
        { source: TEXT, regex: RegexConstants::EXPIRATION_DATE, delimiters: ' ', category: LABELS }
      ],
      gap_binder:                        [
        { source: DOCUMENT_TEXT, regex: RegexConstants::GAP_FORM_NUMBER, delimiters: ' :', category: LABELS }
      ],
      gap_waiver_contract:               [
        { source: DOCUMENT_TEXT, regex: RegexConstants::GAP_FORM_NUMBER, delimiters: ' :', category: LABELS }
      ],
      vehicle_service_contract:          [
        { source: DOCUMENT_TEXT, regex: RegexConstants::VSC_TERM_LABEL, delimiters: ' :.', category: LABELS },
        { source: DOCUMENT_TEXT, regex: RegexConstants::FORM_NUMBER, delimiters: ' :.', category: LABELS }
      ]
    }.freeze
    # rubocop:enable Layout/LineLength

    COMBINE_WORDS_REGEX ||= [
      { source: DOCUMENT_TEXT, regex: /((?:Social|Soc(?:\s)?(?:\.)?) (?:Security|Sec(?:\s)?(?:\.)?)(?:\s(?:tax|Number|No)(?:\s)?(?:\.)?)?)/i, delimiters: ' .\n', category: LABELS }, # rubocop:disable Layout/LineLength
      { source: DOCUMENT_TEXT, regex: AddressHelper::STATE_ZIP_REGEX, delimiters: ', ' }
    ].freeze

    UNCAPTURED_DATE_REGEX ||= Regexp.union(RegexConstants::UNCAPTURED_MONTHDDYY, RegexConstants::UNCAPTURED_DDMONTHYY).freeze # rubocop:disable Layout/LineLength

    class << self
      def combine_words(vision_data, document_type)
        return vision_data unless [DOCUMENT_TEXT, TEXT].any? { |k| vision_data&.key?(k) }
        return vision_data unless vision_data.dig(DOCUMENT_TEXT, COMBINED_WORDS).blank?
        process_ocr_words(vision_data, document_type)
      end

      def recombine_words(vision_data, document_type)
        return vision_data unless [DOCUMENT_TEXT, TEXT].any? { |k| vision_data&.key?(k) }
        vision_data[DOCUMENT_TEXT][COMBINED_WORDS] = nil if vision_data.key?(DOCUMENT_TEXT)
        vision_data[TEXT][COMBINED_WORDS] = nil if vision_data.key?(TEXT)
        vision_data[DOCUMENT_TEXT][COMBINED_INDICES] = nil if vision_data.key?(DOCUMENT_TEXT)
        vision_data[TEXT][COMBINED_INDICES] = nil if vision_data.key?(TEXT)
        [DOCUMENT_TEXT, TEXT].each { |src| COMBINED_CATEGORIES.each { |cat| vision_data[src][cat] = nil if vision_data[src]&.key?(cat) } } # rubocop:disable Layout/LineLength
        process_ocr_words(vision_data, document_type)
      end

      def regroup_words(vision_data)
        return vision_data unless [DOCUMENT_TEXT, TEXT].any? { |k| vision_data&.key?(k) }
        [DOCUMENT_TEXT, TEXT].each do |src|
          next unless vision_data.key?(src)
          vision_data[src][GROUPED_WORDS] = spatially_group_words(vision_data_unique_words(vision_data, src))
        end
        vision_data
      end

      def group_words_from(unique_words)
        spatially_group_words(unique_words)
      end

      def combine_words_for(vision_page_source, document_type)
        process_ocr_words_for(vision_page_source, document_type)
      end

      # words must be array of VisionWords
      # Regexes must be in same format as above hashes
      def combine_words_in_section(vision_data, words, source, regexes)
        new_data = { source.to_s => { 'words' => words, 'text' => vision_data.dig(source, 'text') } }
        regexes.each do |cwr|
          process_combination_words_regex(new_data, cwr[:source], cwr[:regex], cwr[:delimiters], cwr[:category])
        end
        new_data
      end

      # Does this need to be updated to take in doc type and stip types?
      def combine_for_the_given_words(vision_data, source, words, delimiters)
        # have to give source here because our code expects it everywhere
        vision_data = vision_data.dup
        vision_data[source][COMBINED_WORDS] = nil
        vision_data[source][COMBINED_INDICES] = nil
        process_combination_words(vision_data, source, words, delimiters, nil)
        vision_data[source][COMBINED_WORDS]
      end

      private

      def process_ocr_words(vision_data, document_type)
        combine_date_words(vision_data)
        combine_words_regex(vision_data, document_type)
        vision_data
      end

      def process_ocr_words_for(vision_page_source, document_type)
        combine_date_words_for(vision_page_source)
        combine_words_regex_for(vision_page_source, document_type)
      end

      def combine_words_regex(vision_data, document_type)
        document_regexes(document_type).each do |cwr|
          process_combination_words_regex(vision_data, cwr[:source], cwr[:regex], cwr[:delimiters], cwr[:category])
        end
      end

      def combine_words_regex_for(vision_page_source, document_type)
        document_regexes(document_type).each do |cwr|
          process_combination_words_regex_for(vision_page_source, cwr[:regex], cwr[:delimiters], cwr[:category])
        end
      end

      def document_regexes(document_type)
        shared_regexes = SHARED_COMBINATION_REGEXES.values_at(*DOCUMENT_SHARED_MAP[document_type.to_sym]).flatten || []
        [*shared_regexes, *(DOCUMENT_COMBINATION_REGEXES[document_type.to_sym] || []), *COMBINE_WORDS_REGEX]
      end

      def combine_date_words(vision_data)
        vision_text = vision_data&.dig(DOCUMENT_TEXT, 'corrected_text')
        vision_text = vision_data&.dig(DOCUMENT_TEXT, 'text') unless vision_text.present?
        return unless vision_text.present?
        combination_words = []
        combination_words += vision_text.split.grep(RegexConstants::ALL_DATE)
        combination_words += vision_text.scan(UNCAPTURED_DATE_REGEX).map(&:compact).map { |d| d.join(' ') }
        process_combination_words(vision_data, DOCUMENT_TEXT, combination_words.flatten.compact, "/._:, '-", DATES)
      end

      def combine_date_words_for(vision_page_source)
        vision_text = vision_page_source.corrected_text.blank? ? vision_page_source.text : vision_page_source.corrected_text # rubocop:disable Layout/LineLength
        return if vision_text.blank?
        combination_words = []
        combination_words.append(*vision_text.split.grep(RegexConstants::ALL_DATE))
        combination_words += vision_text.scan(UNCAPTURED_DATE_REGEX).map(&:compact).map { |d| d.join(' ') }
        process_combination_words_for(vision_page_source, combination_words.flatten.compact, "/._:, '-", DATES)
      end

      def process_combination_words_for(vision_page_source, combination_words, delimiters, category)
        combined_words_text = vision_page_source.combined_words.map { |word| word['text'] }
        corrected_map_inverted = vision_page_source.corrected_spelling_map&.invert
        combination_words&.compact&.uniq&.each do |combine_word|
          next if combined_words_text.include?(combine_word)
          # TODO: delimiters should be regex in hash up top
          split_combine_word = combine_word.split(delimiters == '' ? delimiters : /([#{delimiters}])/).select(&:present?) # rubocop:disable Layout/LineLength
          original_words_length = corrected_map_inverted&.dig(combine_word)&.split(delimiters == '' ? delimiters : /([#{delimiters}])/)&.select(&:present?)&.size # rubocop:disable Layout/LineLength
          # TODO: There's a generic function (bounds_across) in DocumentOcrAnalysis
          # Switch to that after verifying it works
          vision_page_source.words.each_cons(original_words_length || split_combine_word.length).with_index do |words, base_index| # rubocop:disable Layout/LineLength
            # Figure out if the split combine word (based off of corrected text) matches ocr words
            words_corrected_text = words.map(&:corrected_text)
            words_text = words.map(&:text).join
            exact_match = words_corrected_text.map(&:downcase) == split_combine_word.map(&:downcase)
            corrected_match = !exact_match && vision_page_source.corrected_spelling_map&.dig(words_text) == combine_word
            next unless exact_match || corrected_match
            indices = (base_index...(base_index + split_combine_word.length))
            next if indices.any? { |index| vision_page_source.combined_indices&.include?(index) }
            # We also need to check if we are combining set of words that are conceivably close to each other
            #
            # In the future, this gap of font width * 6 needs to be customizable; e.g passed into regexes as a parameter
            # For now, this gap has been expanded from 3 to 6 for the use cases of partial dates in us bank deposits
            # and the regex DEPOSITS_POSTING_DATE for td bank deposits
            next if words.each_cons(2).map { |w1, w2| w2.min_x - w1.max_x }.max.to_f > words.map(&:font_width).max * 6 && category != 'percent' # rubocop:disable Layout/LineLength
            # Correct ocr words values that weren't previously corrected (e.g. cases like y-t-o -> y-t-d)
            if corrected_match && words.size == split_combine_word.size
              words.each_with_index do |word, index|
                word['corrected_text'] = split_combine_word[index] unless word.text.casecmp?(split_combine_word[index])
              end
            end
            original_text = split_combine_word.size == words_text.size ? words_text : splice_spaces_into_text(combine_word) # rubocop:disable Layout/LineLength
            word_hash = { 'text' => original_text, 'bounds' => combine_bounds(words), 'indices' => indices.to_a, 'corrected_text' => combine_word } # rubocop:disable Layout/LineLength
            word_hash['category'] ||= category
            vw = VisionWord.factory(word_hash)
            vision_page_source.combined_words.push(vw)
            vision_page_source.combined_indices.push(*indices)
            vision_page_source.send(category) << vw if category.present?
          end
        end
        vision_page_source
      end

      def process_combination_words(vision_data, words_src, combination_words, delimiters, category)
        all_words = vision_data&.dig(words_src, 'words')
        vision_data[words_src][COMBINED_WORDS] ||= []
        vision_data[words_src][COMBINED_INDICES] ||= []
        vision_data[words_src][category] ||= [] if category.present?
        combined_words_text = vision_data[words_src][COMBINED_WORDS].map { |word| word['text'] }
        corrected_map_inverted = vision_data.dig(words_src, 'corrected_spelling_map')&.invert
        combination_words&.compact&.uniq&.each do |combine_word|
          next if combined_words_text.include?(combine_word)
          # TODO: delimiters should be regex in hash up top
          split_combine_word = combine_word.split(delimiters == '' ? delimiters : /([#{delimiters}])/).select(&:present?) # rubocop:disable Layout/LineLength
          original_words_length = corrected_map_inverted&.dig(combine_word)&.split(delimiters == '' ? delimiters : /([#{delimiters}])/)&.select(&:present?)&.size # rubocop:disable Layout/LineLength
          # TODO: There's a generic function (bounds_across) in DocumentOcrAnalysis
          # Switch to that after verifying it works
          all_words.each_cons(original_words_length || split_combine_word.length).with_index do |words, base_index|
            # Figure out if the split combine word (based off of corrected text) matches ocr words
            words_corrected_text = words.map { |word| word.fetch('corrected_text', word['text']) }
            words_text = words.map { |word| word['text'] }.join
            exact_match = words_corrected_text.map(&:downcase) == split_combine_word.map(&:downcase)
            corrected_match = !exact_match && vision_data.dig(words_src, 'corrected_spelling_map', words_text) == combine_word # rubocop:disable Layout/LineLength
            next unless exact_match || corrected_match
            indices = (base_index...(base_index + split_combine_word.length))
            next if indices.any? { |index| vision_data[words_src][COMBINED_INDICES].include?(index) }
            # We also need to check if we are combining set of words that are conceivably close to each other
            vision_words = VisionWord.factory(words)
            space = vision_words.map(&:font_width).max * 6
            next if vision_words.each_cons(2).map { |w1, w2| w2.min_x - w1.max_x }.max.to_f > space && category != 'percent' # rubocop:disable Layout/LineLength
            # Correct ocr words values that weren't previously corrected (e.g. cases like y-t-o -> y-t-d)
            if corrected_match && words.size == split_combine_word.size
              words.each_with_index do |word, index|
                word['corrected_text'] = split_combine_word[index] unless word['text'].casecmp?(split_combine_word[index]) # rubocop:disable Layout/LineLength
              end
            end
            original_text = split_combine_word.size == words_text.size ? words_text : splice_spaces_into_text(combine_word) # rubocop:disable Layout/LineLength
            word_hash = { 'text' => original_text, 'bounds' => combine_bounds(words), 'indices' => indices.to_a, 'corrected_text' => combine_word } # rubocop:disable Layout/LineLength
            word_hash['category'] ||= category
            vw = VisionWord.factory(word_hash)
            vision_data[words_src][COMBINED_WORDS].push(vw)
            vision_data[words_src][COMBINED_INDICES].push(*indices)
            vision_data[words_src][category].push(vw) if category.present?
          end
        end
        vision_data
      end

      # FIXME: We want to combine based on the original text. The problem is that in some cases we don't know where the
      # spaces are in the original text since ocr words doesn't contain them. What this function should do is look at
      # original text to figure out where the spaces are and splice them into the word. The problem is that we don't
      # have the original text when this is called so for now it's just returning what's passed in
      def splice_spaces_into_text(word)
        word
      end

      def process_combination_words_regex(vision_data, words_src, regex, delimiters, category)
        combination_words = (vision_data.dig(words_src, 'corrected_text') || vision_data.dig(words_src, 'text'))&.scan(regex)&.uniq # rubocop:disable Layout/LineLength
        return unless combination_words&.flatten&.compact&.present?
        sorted_combined_words = combination_words.flatten.compact.sort_by { |a| -a.length }
        process_combination_words(vision_data, words_src, sorted_combined_words, delimiters, category)
      end

      def process_combination_words_regex_for(vision_page_source, regex, delimiters, category)
        vision_text = vision_page_source.corrected_text.blank? ? vision_page_source.text : vision_page_source.corrected_text # rubocop:disable Layout/LineLength
        combination_words = vision_text&.scan(regex)&.uniq
        return if combination_words&.flatten&.compact.blank?
        sorted_combined_words = combination_words.flatten.compact.sort_by { |a| -a.length }
        process_combination_words_for(vision_page_source, sorted_combined_words, delimiters, category)
      end
    end
  end
end
