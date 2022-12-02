require_relative 'connected_word'
require_relative 'connected_box'
require_relative 'gva_wrapper'
require_relative 'document_ocr_analysis'

module VisionPackage
  module ComputerVisionData
    include VisionPackage::DocumentOcrAnalysis

    def document_vision
      {
        vision_data:  merged_data,
        image_blocks: image_blocks
      }.with_indifferent_access
    end

    def document_text_words
      retrieve_unique_words(GvaWrapper::DOCUMENT_TEXT)
    end

    def text_words
      retrieve_unique_words(GvaWrapper::TEXT)
    end

    def ocr_text
      (merged_data&.dig(GvaWrapper::TEXT, 'text') || '') + (merged_data&.dig(GvaWrapper::DOCUMENT_TEXT, 'text') || '')
    end

    def ocr_corrected_text
      (merged_data&.dig(GvaWrapper::DOCUMENT_TEXT, 'corrected_text') || ocr_text)
    end

    def ocr_words
      document_text_words + text_words
    end

    def ocr_paragraphs
      (merged_data&.dig(GvaWrapper::DOCUMENT_TEXT, 'paragraphs') || [VisionPackage::VisionWord.factory('text' => ocr_text, 'bounds' => [])]) # rubocop:disable Layout/LineLength
    end

    def ocr_unique_text(options = {})
      document_text_first = options.fetch(:document_text_first, true)

      vision_data_unique_text(merged_data, document_text_first: document_text_first)
    end

    def ocr_unique_words
      ocr_words.map(&:text).uniq
    end

    # list of words without duplication of combined words and parts of combined words
    def retrieve_unique_words(src)
      merged_data&.dig(src, 'unique_words') || []
    end

    def combined_words(src = GvaWrapper::DOCUMENT_TEXT)
      words_by_combined_category(GvaWrapper::COMBINED_WORDS, src)
    end

    def label_words(src = GvaWrapper::DOCUMENT_TEXT)
      words_by_combined_category(GvaWrapper::LABELS, src)
    end

    def percent_words(src = GvaWrapper::DOCUMENT_TEXT)
      words_by_combined_category(GvaWrapper::PERCENT, src)
    end

    def ssn_words(src = GvaWrapper::DOCUMENT_TEXT)
      (words_by_combined_category(GvaWrapper::SSN, src) + grouped_words(src).select(&:ssn?)).uniq
    end

    def date_words(src = GvaWrapper::DOCUMENT_TEXT, options = {})
      include_partials = options.fetch(:include_partials, false)

      dates = words_by_combined_category(GvaWrapper::DATES, src).reject(&:dollar?)
      dates = (dates + grouped_words(src).select { |w| w.date? || w.partial_date? }).uniq
      include_partials ? dates : dates.reject(&:partial_date?)
    end

    def partial_date_words(src = GvaWrapper::DOCUMENT_TEXT)
      date_words(src, include_partials: true).select(&:partial_date?)
    end

    def date_words_with_partial(src = GvaWrapper::DOCUMENT_TEXT)
      date_words(src, include_partials: true)
    end

    def dollar_words(src = GvaWrapper::DOCUMENT_TEXT)
      @dollar_words ||= {}
      @dollar_words[src] ||= (words_by_combined_category(GvaWrapper::DOLLAR_AMOUNTS, src) + grouped_words(src).select(&:dollar?)).uniq # rubocop:disable Layout/LineLength
    end

    def hours_words(src = GvaWrapper::DOCUMENT_TEXT, options = {})
      strict = options.fetch(:strict, true)

      @hours_words ||= {}
      @hours_words[src] ||= retrieve_unique_words(src).select { |x| x.hours?(strict: strict) }
    end

    def hourly_rate_words(src = GvaWrapper::DOCUMENT_TEXT)
      retrieve_unique_words(src).select(&:hourly_rate?)
    end

    def vin_words(src = GvaWrapper::DOCUMENT_TEXT)
      @vin_words ||= {}
      @vin_words[src] ||= (words_by_combined_category(GvaWrapper::VIN, src) + retrieve_unique_words(src).select(&:vin?)).uniq # rubocop:disable Layout/LineLength
    end

    def odometer_words(src = GvaWrapper::DOCUMENT_TEXT, options = {})
      min = options.fetch(:min, nil)

      @odometer_words ||= {}
      @odometer_words[src] ||= {}
      @odometer_words[src][min] ||= combined_words(src).uniq.select { |w| w.category.in?([GvaWrapper::ODOMETER, GvaWrapper::DATES]) && w.odometer?(min: min || 1_000) } # rubocop:disable Layout/LineLength
    end

    def value_words(src = GvaWrapper::DOCUMENT_TEXT)
      grouped_words(src).select(&:formattable?)
    end

    def words_by_combined_category(category, src = GvaWrapper::DOCUMENT_TEXT)
      merged_data&.dig(src, category) || []
    end

    def document_text_combined_words
      combined_words(GvaWrapper::DOCUMENT_TEXT)
    end

    def grouped_words(src = GvaWrapper::DOCUMENT_TEXT)
      merged_data&.dig(src, GvaWrapper::GROUPED_WORDS) || []
    end

    def document_text_grouped_words
      grouped_words(GvaWrapper::DOCUMENT_TEXT)
    end

    def sorted_grouped_words(src = GvaWrapper::DOCUMENT_TEXT)
      words = grouped_words(src)
      sort_words_horizontally(words)
    end

    def sorted_ocr_unique_text
      sorted_words = sorted_grouped_words
      return ocr_unique_text unless sorted_words.present?
      sorted_words.map(&:text).join(' ')
    end

    def connected_words(source = GvaWrapper::DOCUMENT_TEXT)
      @connected_words ||= {}
      @connected_words[source] ||= ConnectedWord.create_from_document(self, source)
    end

    def left_connected_word(word)
      @left_connected_word ||= {}
      @left_connected_word[word] ||= ConnectedWord.left_closest_connection(word, self, GvaWrapper::DOCUMENT_TEXT)
    end

    def top_connected_word(word)
      @top_connected_word ||= {}
      @top_connected_word[word] ||= ConnectedWord.top_closest_connection(word, self, GvaWrapper::DOCUMENT_TEXT)
    end

    def connected_labels(word)
      [left_connected_word(word), top_connected_word(word)].compact
    end

    def connected_boxes
      @connected_boxes ||= {}
      @connected_boxes[cache_key] ||= ConnectedBox.create_from_document(self)
    end

    def vision_boxes
      @vision_boxes ||= {}
      @vision_boxes[cache_key] ||= VisionBox.create_from_document(self)
    end

    def find_all_dates(source = GvaWrapper::DOCUMENT_TEXT)
      @find_all_dates ||= {}
      @find_all_dates[source] ||= date_words(source).map(&:to_date).compact
    end

    def ocr_text_from(source = GvaWrapper::DOCUMENT_TEXT)
      GvaWrapper::CATEGORIES.include?(source) ? (merged_data&.dig(source, 'text') || '') : ocr_text
    end

    def find_all_dollar_amounts_from_text(source = GvaWrapper::DOCUMENT_TEXT)
      find_dollar_amounts_in_text(ocr_text_from(source))
    end

    def rotation_angle
      # We can be smarter by only choosing the important words (words that have been used for extractions)
      @angle ||= angle_across(font_words)
    end

    def minimum_x
      [0, document_text_words.map(&:min_x).min.to_i].max
    end

    def minimum_y
      [0, document_text_words.map(&:min_y).min.to_i].max
    end

    def maximum_x
      max_x = document_text_words.map(&:min_x).max
      (max_x.nil? || max_x > 2400) ? 1200 : max_x
    end

    def maximum_y
      max_y = document_text_words.map(&:min_y).max
      (max_y.nil? || max_y > 1600) ? 1600 : max_y
    end

    def content_width
      maximum_x - minimum_x
    end

    def content_height
      maximum_y - minimum_y
    end

    def find_all_ocr_words_regex(word_to_find, words = ocr_words)
      words.select { |word| word.match?(/#{sanitize_regex_string(word_to_find)}/i, true) }
    end

    def find_all_ocr_words_by_regex(regex, words = ocr_words)
      words.select { |word| word.match?(regex, true) }
    end

    # return words with exact match
    def find_exact_ocr_words(words_to_find)
      # words can have spaces in them. We need to make sure all the individual words can be matched
      matching_words = []
      words_to_find.split.each do |word|
        match_word = ocr_words.find { |ocr_word| ocr_word.match?(/^#{sanitize_regex_words(word)}$/i) }
        return nil unless match_word.present?
        matching_words.push(match_word)
      end
      # We should combine the bounds of all the words and send it back (What happens if the names are on separate lines)
      matching_words.first
    end

    # returns first instance of word, if any, within ocr_words
    def find_ocr_words_regex(words_to_find)
      # words can have spaces in them. We need to make sure all the individual words can be matched
      matching_words = []
      words_to_find.split.each do |word|
        match_word = ocr_words.find { |ocr_word| ocr_word.match?(/#{sanitize_regex_words(word)}/i) }
        return nil unless match_word.present?
        matching_words.push(match_word)
      end
      # We should combine the bounds of all the words and send it back (What happens if the names are on separate lines)
      matching_words.first
    end

    # return the row data which contains the matching word
    def find_words_regex_by_row(word_to_find, exact_match = false)
      matching_words = []
      return matching_words unless ocr_text.present?
      ocr_text.split("\n").each do |row_text|
        if exact_match
          matching_words.push(row_text) if row_text.split.grep(/^#{sanitize_regex_words(word_to_find)}$/i).present?
        elsif row_text.match?(/#{sanitize_regex_words(word_to_find)}/i)
          matching_words.push(row_text)
        end
      end
      matching_words
    end

    # not restrict the adjacent rows to the immediate one
    # since rows is defined by ocr reading, different font might end in different row
    # also mexico id, they have given names and family names separate with labels
    def find_adjacent_rows_by_src(src_word, rows_num = 4)
      return unless src_word.present?
      adjacent_rows = []
      ocr_paragraphs.each do |paragraph|
        next unless paragraph.text.present?
        adjacent_rows = construct_adjacent_rows(paragraph.text.split("\n"), src_word, rows_num)
        break unless adjacent_rows.empty?
      end
      return adjacent_rows if adjacent_rows.length > rows_num || !ocr_text.present?
      # make sure we have at least 5-6 adjacent rows data to test
      ocr_text_rows = construct_adjacent_rows(ocr_text.split("\n"), src_word, rows_num)
      adjacent_rows | ocr_text_rows
    end

    def construct_adjacent_rows(rows, src_word, rows_num)
      return [] if !rows.present? || src_word.nil?
      adjacent_rows = []
      rows.each_with_index do |row_text, row_index|
        next unless row_text.match?(/#{sanitize_regex_words(src_word)}/i)
        if row_index.positive?
          start_index = (row_index - rows_num).positive? ? row_index - rows_num : 0
          adjacent_rows += rows[start_index..row_index - 1]
        end
        if row_index < rows.length - 1
          end_index = row_index + rows_num > rows.length - 1 ? rows.length - 1 : row_index + rows_num
          adjacent_rows += rows[row_index + 1..end_index]
        end
        return adjacent_rows
      end
      adjacent_rows
    end

    def font_words
      @font_words ||= document_text_words.present? ? document_text_words : text_words
    end

    def avg_font_size
      @avg_font_size ||= font_words.map(&:font_height).sum.fdiv(font_words.count)
    end

    def avg_font_width
      @avg_font_width ||= font_words.map(&:font_width).sum.fdiv(font_words.count)
    end

    def vertical_range
      @vertical_range ||= minmax_y(ocr_words)
    end

    def one_char_off(word1, word2)
      word1.chars.select.with_index { |val, idx| word2.chars[idx] != val }.count == 1 && word1.size == word2.size
    end

    # Pretty rudimentary for now, will update once it's actually used for something
    # Might want to incorporate the combine_words logic here too
    def text_to_bounds(text)
      results = document_text_words.select { |word| JaroWinkler.distance(word.text, text, ignore_case: true) > 0.95 || (text.size > 2 && one_char_off(word.text, text)) } # rubocop:disable Layout/LineLength
      return results if results.present?
      ocr_paragraphs.grep(/#{text}/i)
    end

    def tables_pretty_print
      tables.each_with_index { |t, ind| pretty_print_table(t, ind) }
    end

    def potentially_bad_ocr?(word)
      dollar_too_wide?(word) || incorrect_dollar_amount?(word)
    end

    def incorrect_dollar_amount?(dollar)
      dollar_with_five?(dollar) || dollar_no_decimal?(dollar)
    end

    def dollar_no_decimal?(dollar)
      return false if dollar.match?(/[.,]/)
      dollar_words.grep(/[.,]/).count.fdiv(dollar_words.count) > 0.7
    end

    def dollar_with_five?(dollar)
      return false unless dollar.dollar_amount.abs.to_s.starts_with?('5') && !dollar.text.match?(/^(S|\$)/i)
      dollar_words.grep(/^[-(]?(5|\$|S)/i).count.fdiv(dollar_words.count) > 0.6
    end

    def dollar_too_wide?(dollar)
      dollar.font_width > avg_dollar_font_width * 1.5
    end

    def avg_dollar_font_width
      @avg_dollar_font_width ||= dollar_words.map(&:font_width).sum.fdiv(dollar_words.length)
    end
  end
end
