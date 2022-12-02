module VisionPackage
  module DocumentOcrAnalysis
    include Math
    include GeometryHelper
    include VisionWordsHelper

    def y_offsets(page_heights)
      [0] + page_heights.to(-2).each_with_index.map { |_, index| page_heights.to(index).reduce(&:+) }
    end

    def generate_date(m, d, y)
      m, d, y = [m, d, y].map { |x| x.to_s.upcase.tr('O', '0').tr('B', '8').tr('S', '5') }
      y_pattern = y.to_i < 100 ? 'y' : 'Y'
      Date.strptime("#{m.to_i}-#{d.to_i}-#{y.to_i}", "%m-%d-%#{y_pattern}")
    rescue
      nil
    end

    def to_date(word)
      Honeybadger.notify(Exception.new('DocumentOcrAnalysis.to_date is DEPRECATED'), tags: 'low_priority')
      VisionPackage::VisionText.to_date(word)
    end

    def sanitize_regex_string(string)
      Regexp.quote(string)
    end

    def sanitize_regex_words(words)
      words.split('|').each { |word| sanitize_regex_string(word) }.join('|')
    end

    def vertical_word_in_direction(word, all_words, bottom = true)
      position = bottom ? :bottom : :top
      vertical_words = all_words.select { |w| word.send("intersects_#{position}?", w) }
      bottom ? vertical_words.min_by(&:min_y) : vertical_words.max_by(&:min_y)
    end

    def sort_words_horizontally(words)
      words&.sort do |a, b|
        avg_font = [1, [a, b].map(&:font_height).sum.fdiv(2)].max
        a.centroid.y.div(avg_font) == b.centroid.y.div(avg_font) ? a.min_x <=> b.min_x : a.centroid.y <=> b.centroid.y
      end
    end

    def connected?(labels, val, horizontal_tolerance = nil)
      connected_left?(labels, val, horizontal_tolerance) || connected_top?(labels, val)
    end

    def connected_left?(labels, val, tolerance = nil)
      labels.any? do |l|
        val.intersects_left?(l) ||
          ((val.connected_horizontally?(l, tolerance) && val.relative_position(l).include?(:left)) &&
            val.distance_to(l) <= val.font_width * 50)
      end
    end

    def connected_top?(labels, val)
      labels.any? do |l|
        (val.intersects_top?(l) || (val.connected_vertically?(l) && val.relative_position(l).include?(:top))) &&
          val.distance_to(l) <= val.font_height * 30
      end
    end

    def find_dollar_amounts_in_text(text)
      return [] unless text.present?
      text.scan(RegexConstants::CURRENCY).map { |d| VisionPackage::VisionText.dollar_amount(d) }
    end

    # FIXME: This logic is incomplete and will only work for the demo documents. Real 1040s will have a different format
    def find_dollar_amounts_in_tax_document(document, src = GvaWrapper::DOCUMENT_TEXT)
      words = document.retrieve_unique_words(src)
      return [] unless words.present?
      words.map.with_index do |word, idx|
        previous = words[idx - 1].text if idx > 1
        text = word.text
        next unless text.match?(/^[1-9]{1}\d{2,5}$/)
        next if text.size == 5 && previous&.match?(AddressHelper::STATE_REGEX) # Not a zipcode
        next if text.size == 4 && text.starts_with?('201') # Not a year
        next if previous&.match?(/fo(r)?m|section/i) # Not a form/section number
        VisionWord.factory(word)
      end.compact
    end

    def word_to_polygon(word)
      Polygon.new(VisionWord.factory(word).points)
    end

    def points_to_polygon(points)
      Polygon.new(points.map { |point| Point(point.first, point.second) })
    end

    # return a list of words that are contained within a polygon
    def words_contained_in_polygon(polygon, words, options = {})
      strict = options.fetch(:strict, true)

      filter = proc do |pol, list|
        list.select { |word| polygon_contains_word?(pol, word, strict: strict) }
      end
      filter_words_in_shape(polygon, words, filter)
    end

    def filter_words_in_shape(shape, words, filter)
      return [] unless words.present?
      filter.call(shape, words)
    end

    # if a centroid of a word is within a polygon, then this word
    # is within the polygon
    def polygon_contains_word?(polygon, word, options = {})
      strict = options.fetch(:strict, true)

      word_poly = word_to_polygon(word)
      return false if strict && word_poly.area >= polygon.area
      polygon.contains?(VisionWord.factory(word).centroid)
    end

    def polygon_contains_line?(polygon, line)
      p1, p2 = line['points']
      polygon.contains?(Point(p1.first, p1.second)) && polygon.contains?(Point(p2.first, p2.second))
    end

    # check if polygon_1 contains polygon_2
    # if all the points of polygon_2 are contained in polygon_1, return yes
    def polygon_contains_polygon?(polygon1, polygon2)
      src_polygon = points_to_polygon(polygon1['points'])
      polygon2['points'].all? { |point| src_polygon.contains?(Point(point.first, point.second)) }
    end

    # FIXME: Consolidate with VisionWord.connected?
    def word_connected?(a, b, options = {})
      skip_distance_check = options.fetch(:skip_distance_check, false)

      return unless a.present? && b.present?
      a, b = VisionWord.factory([a, b])
      connected = a.connected_on_slope?(b)
      return connected if !connected || skip_distance_check
      word_distance = a.distance_to(b).abs
      # if both a,b are special characters and not far away from each other <8, we treat them connected
      return true if word_distance < 8 && a.match?(/[^0-9a-z]/i) && b.match?(/[^0-9a-z]/i)
      average_font_width = (a.max_x - a.min_x + b.max_x - b.min_x).fdiv(a.length + b.length)
      word_distance < average_font_width * 3
    end

    def sort_words_row_first(words, same_row = false)
      return unless words.present?
      VisionWord.factory(words).sort do |a, b|
        a.intersects_horizontally?(b) || same_row ? a.max_x <=> b.max_x : a.max_y <=> b.max_y
      end
    end

    def angle_bet_three_coords(coord1, coord2, coord3)
      angle_bet_two_slopes(Bounds.slope(coord1, coord2), Bounds.slope(coord2, coord3))
    end

    def angle_bet_two_slopes(m1, m2)
      numerator = m1 - m2
      denominator = 1 + (m1 * m2)
      tan = numerator / denominator
      (Math.atan(tan) * 180) / Math::PI
    end

    def angle_bet_three_words(word1, word2, word3)
      {
        left_align:   angle_bet_three_coords(word1.bottom_left, word2.bottom_left, word3.bottom_left),
        right_align:  angle_bet_three_coords(word1.bottom_right, word2.bottom_right, word3.bottom_right),
        centre_align: angle_bet_three_coords(word1.centroid, word2.centroid, word3.centroid)
      }
    end

    def duplicate_word?(word1, word2)
      min_area = [word1.area, word2.area].min
      Bounds.area_overlap(word1, word2, padding: 0).fdiv(min_area) > 0.95
    end

    # Gives you words which might intersect on a combination of a particular row label, and one column label
    # order the points of a line with smaller x point first
    def reorder_points(lines)
      return unless lines.present?
      lines.map do |point|
        first, second = point['points']
        first_x, first_y = first
        second_x, second_y = second
        first_x > second_x || (first_x == second_x && first_y > second_y) ? point.merge('points' => [second, first]) : point # rubocop:disable Layout/LineLength
      end
    end

    # order the lines with axis value
    def lines_order_by_axis!(lines, axis)
      return unless lines.present?
      lines.sort! do |a, b|
        points_a = min_x_y_of_line(a)
        points_b = min_x_y_of_line(b)

        if points_a[axis] == points_b[axis]
          compare_axis = axis == :x ? :y : :x
          points_a[compare_axis] <=> points_b[compare_axis]
        else
          points_a[axis] <=> points_b[axis]
        end
      end
    end

    def lines_order_by_y!(lines)
      lines_order_by_axis!(lines, :y)
    end

    def lines_order_by_x!(lines)
      lines_order_by_axis!(lines, :x)
    end

    def min_x_y_of_line(line)
      first, second = line['points']
      first_x, first_y = first
      second_x, second_y = second
      { x: [first_x, second_x].min, y: [first_y, second_y].min }
    end

    # With a given ordered lines
    # remove the duplicate lines, and merge the lines together if they are right next to each other
    def smoothing_horizontal_lines(lines)
      return unless lines.present?
      result = []
      temp = []
      lines.each do |line|
        unless temp.present?
          temp.push(line)
          next
        end
        # the line is not on the same y as the lines in temp array
        if lines_on_same_y?([temp, line])
          next if line_existed?(temp, line)
          adjacent_or_intersect_with_existing_lines?(temp, line) ? temp = merge_lines(temp, line) : temp.push(line)
        else
          result += temp
          temp = [line]
        end
      end
      result += temp
      result
    end

    # all lines are on the same y
    def lines_on_same_y?(lines, difference = 5)
      return unless lines.present?
      y_values = lines.flatten.map { |line| values_of_axis(line, 'y').sum.div(2) }
      y_values.max - y_values.min <= difference
    end

    # detect if the line already exists in lines
    def line_existed?(lines, line, on_same_y_checked = true)
      return unless lines.present? && line.present?
      return false if !on_same_y_checked && !lines_on_same_y?([lines, line])
      start_x, end_x = values_of_axis(line, 'x')
      lines.each do |current_line|
        current_start_x, current_end_x = values_of_axis(current_line, 'x')
        return true if start_x == current_start_x && end_x == current_end_x
      end
      false
    end

    def adjacent_or_intersect_with_existing_lines?(lines, line, on_same_y_checked = true)
      return unless lines.present? && line.present?
      return false if !on_same_y_checked && !lines_on_same_y?([lines, line])
      start_x, end_x = values_of_axis(line, 'x')
      lines.each do |current_line|
        current_start_x, current_end_x = values_of_axis(current_line, 'x')
        next if start_x > current_end_x + 7 || end_x + 7 < current_start_x
        return true
      end
      false
    end

    # merge the line with one of existing lines
    def merge_lines(lines, line, on_same_y_checked = true)
      return unless lines.present? && line.present?
      return false if !on_same_y_checked && !lines_on_same_y?([lines, line])
      start_x, end_x = values_of_axis(line, 'x')
      lines.map do |current_line|
        current_start_x, current_end_x = values_of_axis(current_line, 'x')
        if start_x > current_end_x + 7 || end_x + 7 < current_start_x
          current_line
        else
          current_start_y, current_end_y = values_of_axis(current_line, 'y')
          x_values = [start_x, end_x, current_start_x, current_end_x]
          current_line.merge('points' => [[x_values.min, current_start_y], [x_values.max, current_end_y]])
        end
      end
    end

    def values_of_axis(line, axis)
      first, second = line['points']
      first_x, first_y = first
      second_x, second_y = second
      axis == 'x' ? [first_x, second_x] : [first_y, second_y]
    end

    # find all the words that sit right above a line
    def all_words_on_line(words_list, line)
      return unless words_list.present? && line.present?
      func = proc do |line_s, list|
        words = list.map do |word|
          word_on_line(word, line_s)
        end.compact
        # TODO: should pick the one with smaller distance if two words are cross on x
        words.map { |word| word[:word] } if words.present?
      end
      filter_words_in_shape(line, words_list, func)
    end

    # find all the words that are close to a line (left, right, bottom but not on top)
    def all_labels_close_to_line(words_list, line)
      return unless words_list.present? && line.present?
      func = proc do |line_s, list|
        list.map do |word|
          word_close_to_line(word, line_s)
        end.compact
      end
      filter_words_in_shape(line, words_list, func)
    end

    # find the specific y on a line at point with a given x
    def line_y_on_point_x(line, x)
      p1, p2 = line['points']
      slope_of_line = Bounds.slope(p1, p2, false)
      return p2.second if slope_of_line == Float::INFINITY
      p1.second + (slope_of_line * (x - p1.first))
    end

    # words on top of the line (looking for the value)
    # if a word is not on top of the line or too much above the line(1x font height), return nil
    # otherwise, return the value and distance to the line
    # distance is not used now
    def word_on_line(word, line, tolerance = 1)
      word_point = VisionWord.factory(word).centroid
      p1, p2 = line['points']
      return unless word_point.x.between?(p1.first, p2.first)
      line_at_word_y = line_y_on_point_x(line, word_point.x)
      min_y, max_y = minmax(word, 'y')
      distance = line_at_word_y - word_point.y
      return if distance.negative?
      { word: word, distance: distance } if distance < (max_y - min_y) * tolerance
    end

    # detect the word to see if it is a label to the line
    # the word should  be on the same x as line or is right below the line
    def word_close_to_line(word, line)
      p1, p2 = line['points']
      min_y, max_y = minmax(word, 'y')
      min_x, max_x = minmax(word, 'x')
      line_y = (p1.second + p2.second).fdiv(2)
      # word's y should be very close to line's y
      return unless (max_y - line_y).abs < 10 || (!(min_y - line_y).negative? && (min_y - line_y) < 8)
      # if the word is below the line, then it has to be within the line's x range
      average_x = (min_x + max_x) / 2
      return if min_y >= line_y && !average_x.between?(p1.first, p2.first)
      # if the word is on the same line as the line, its x should not be within the line's x range
      return if (max_y - line_y).abs < 10 && average_x.between?(p1.first, p2.first)

      direct = :bottom if min_y >= line_y
      direct ||= max_x < p1.first ? :left : :right
      { word: word, direction: direct }
    end

    def infinity_for_negative(num)
      num.negative? ? Float::INFINITY : num
    end

    # merge the words together with space between
    # if the word is a single non-alphanumeric character, no space should be added before the special charater
    # unless the special character is ',' or '.', don't add a space after the special character
    def construct_phrase(words)
      return unless words.present?
      result = []
      words.each do |a|
        # if result is empty directly add the first element
        # or if last element ends with character, ',', and a starts with an alphanumeric
        # or if the last element ends with '.', but none of last element and a are all numeric number
        # or if either the last word or the current word is a combined word
        # add a to result
        if !result.present? ||
           # combined_word?(result.last) || combined_word?(a) || #TODO talk to bharath
           (result.last.match?(/[0-9a-z,]$/i) && a.match?(/^[0-9a-z(]/i)) ||
           (result.last.match?(/\.$/) && !(result.last.match?(/^[\d,]+\.$/) && a.match?(/^\d+$/))) ||
           result.last.match?(/[:]/) || a.match?(/[:]/)
          result << a
          next
        end
        length = result.length
        result[length - 1] = result.last + a
      end
      result.join(' ')
    end

    # convert points[[x1,y1],[x2,y2],[x3,y3],[x4,y4]] to bounds:[{x=>x1,y=>y1},{x=>x2,y=>y2},{x=>x3,y=>y3},{x=>x4,y=>y4}
    def points_to_bounds(points)
      { 'bounds' => Bounds.new(points).to_h }
    end

    # find the distance and direction between two words on axis
    def words_distance_in_direction(pivot_word, word_to_compare, axis)
      return unless pivot_word.present? && word_to_compare.present?
      p_min, p_max = minmax(pivot_word, axis.to_s)
      w_min, w_max = minmax(word_to_compare, axis.to_s)
      w_to_p_distance = infinity_for_negative(w_min - p_max)
      p_to_w_distance = infinity_for_negative(p_min - w_max)
      return axis == :x ? ['right', w_to_p_distance] : ['bottom', w_to_p_distance] if w_to_p_distance < p_to_w_distance
      axis == :x ? ['left', p_to_w_distance] : ['top', p_to_w_distance]
    end

    # find all the words that are the same line as the checkbox/radiobutton
    def all_words_align_checkbox(words_list, checkbox, axis)
      return unless words_list.present? && checkbox.present?
      func = proc do |box, list|
        checkbox_bounds = Bounds.factory(box['points'])
        # FIXME: This blows up when called from DocumentVision
        list.select do |word|
          func = axis == :x ? 'connected_horizontally?' : 'connected_vertically?'
          checkbox_bounds.public_send(func, VisionWord.factory(word).bounds)
        end.compact
      end
      filter_words_in_shape(checkbox, words_list, func)
    end

    # calculate a polygon area that contains the give word + given range
    def polygon_word_with_range(word, x_range, y_range)
      return unless word.present? && x_range.present? && y_range.present?
      min_x, = minmax(word, 'x')
      min_y, = minmax(word, 'y')
      min_x = 0 if x_range == Float::INFINITY
      { 'points' => [[min_x, min_y], [min_x + x_range, min_y], [min_x + x_range, min_y + y_range], [min_x, min_y + y_range], [min_x, min_y]] } # rubocop:disable Layout/LineLength
    end

    def sanitize_name(name, delims = /[,.]/)
      return if name.nil?
      sanitized_name = name.gsub(/\s*\-\s*/, '-')
      name_with_space = sanitized_name.tr('-', ' ')
      name_with_dash = name_with_space.tr(' ', '-')
      temp_name = name_with_space == name_with_dash ? name_with_dash : "#{name_with_dash}|#{name_with_space}"
      delims.present? ? temp_name.gsub(delims, '') : temp_name
    end

    # consolidate texts with 'document_text' first, default behavior
    def vision_data_unique_text(vision_data, options = {})
      document_text_first = options.fetch(:document_text_first, true)

      return (vision_data&.dig('document_text', 'text') || vision_data&.dig('text', 'text') || '').squish if document_text_first # rubocop:disable Layout/LineLength
      (vision_data&.dig('text', 'text') || vision_data&.dig('document_text', 'text') || '').squish
    end

    # list of words without duplication of combined words and parts of combined words
    # OPTIMIZE: This is a slow function
    def vision_data_unique_words(vision_data, src_text)
      return [] if vision_data.dig('document_text', 'text').blank?
      combined_words = vision_data.dig(src_text, 'combined_words')
      return (vision_data.dig(src_text, 'words') || []).dup if combined_words.nil?
      combined_words = combined_words.map { |word| { 'word' => word, 'index' => word['combined_indices']&.min } }
      combined_indices = vision_data.dig(src_text, 'combined_indices') || []
      words_list = vision_data.dig(src_text, 'words').map.with_index { |w, idx| { 'word' => w, 'index' => idx } } || []
      words_list = words_list.reject { |word| combined_indices.include?(word['index']) }
      unique_words = words_list + combined_words
      sorted = combined_indices.present? ? unique_words.sort { |a, b| a['index'] <=> b['index'] } : unique_words
      sorted.map { |w| w['word'] }
    end

    def vision_data_grouped_words(vision_data)
      vision_data.dig('document_text', 'grouped_words').presence ||
        vision_data_unique_words(vision_data, 'document_text')
    end

    def bounds_across(string, all_words, delimiters)
      words_in_string(string, all_words, delimiters).map { |words| combine_bounds(words) }
    end

    # Returns an array of "words to be combined" => [[VisionWord, VisionWord], [VisionWord, VisionWord]]
    # words_in_string('Gross Pay', all_words, ' ') => [['gross', 'pay'], ['Gross', 'Pay']]
    def words_in_string(string, all_words, delimiters)
      split_string = string.split(delimiters == '' ? delimiters : /([#{delimiters}])/).select(&:present?)
      str_words = []
      all_words.each_cons(split_string.length) do |words|
        str_words.push(words) if words.map(&:text) == split_string
      end
      str_words
    end

    # With the given pivot_words, find the word in values which has the closest distance to one of the pivot words
    # and is within the boundary the pivot_word defines
    # the boundary starts from (pivot_word_x_min - width, pivot_word_y_min)
    # to (pivot_word_x_max + boundary_width_times * width, pivot_word_y_max + boundary_height_times * height)
    def find_closest_word_within_boundary(pivot_words, values, boundary_width_times = 4, boundary_height_times = 4)
      return unless values.present?
      re = []
      pivot_words.each do |label|
        # construct a polygon box
        x_min, x_max = minmax_x(label)
        y_min, y_max = minmax_y(label)
        width = x_max - x_min
        height = y_max - y_min
        label_polygon = Polygon.new([Point(x_min - width, y_min), Point(x_max + (boundary_width_times * width), y_min),
                                     Point(x_max + (boundary_width_times * width), y_max + (boundary_height_times * height)), Point(x_min - width, y_max + (boundary_height_times * height))]) # rubocop:disable Layout/LineLength
        values.each do |value|
          # only take the values that are inside the polygon box
          next unless polygon_contains_word?(label_polygon, value)
          re.push('d' => VisionWord.distance_between(value, label), 'v' => value)
        end
      end
      return unless re.present?
      re.min_by { |item| item['d'] }&.dig('v', 'text')
    end

    # group a sorted words in rows
    def words_grouped_in_rows(words, sorted = false, tolerance = nil)
      return unless words.present?
      result = []
      words = sort_words_row_first(words) unless sorted
      row = []
      words.each do |word|
        # add the word if it is the first word in row
        if row.empty?
          row << word
          next
        end
        connected_to_last_word_on_slope = VisionWord.factory(word).connected_on_slope?(VisionWord.factory(row.last), tolerance) # rubocop:disable Layout/LineLength
        right_next_to_last_word = VisionWord.factory(word).min_x + 5 >= VisionWord.factory(row.last).max_x
        if connected_to_last_word_on_slope && right_next_to_last_word
          row << word
        else
          result << row
          row = [word]
        end
      end
      result << row if row.present?
      result
    end

    # given two words, decide which one is left, which one is right
    # it will return [left, right]
    def left_right(a, b)
      a, b = VisionWord.factory([a, b])
      a.min_x < b.min_x ? [a, b] : [b, a]
    end

    # given a list of words, it sorts the words first, then combine words to phrases if they are close enough
    # or return the words as it is if they are not close
    def combine_words_in_row(words, same_row = false)
      return unless words.present?
      words = sort_words_row_first(words, same_row)
      result = []
      temp_words = []
      words.map do |word|
        next temp_words << word if temp_words.last.nil? || word_connected?(temp_words.last, word)
        result << merge_words_to_text(temp_words)
        temp_words = [word]
      end
      result << merge_words_to_text(temp_words)
      VisionWord.factory(result.compact)
    end

    # merge words to a phrase, add ' ' between words only when it needs to
    def merge_words_to_text(words)
      return unless words.present?
      {
        'text'   => construct_phrase(words.map(&:text)), # removed extra spaces
        'bounds' => combine_bounds(words)
      }
    end

    def pretty_print_table(t, ind = nil)
      rows = Hash.new([].freeze)
      t.cells.each do |c|
        rows[c.row_id] += [c]
      end
      puts " ---- Table #{ind + 1} ----- " if ind.present?
      table_rows = []
      rows.sort_by { |k, _| k }.to_h.each do |_, cols|
        col_data = []
        cols.sort_by(&:col_id).each do |c|
          col_data << c.text
        end
        table_rows << col_data
      end
      puts "#{Hirb::Helpers::Table.render(table_rows)}\n"
    end

    def date_ranges_in_text(text, regex = RegexConstants::ALL_DATE)
      text.scan(/#{regex}[ ]?(?:-|to[:]?|through|thru[:]?|>>|»)[ ]?#{regex}/i).map(&:compact)
    end

    def sanitized_full_address(str)
      GeocodeHelper.geocode(str).full_address.gsub(/, USA|, United States/, '')
    end

    def combine_words_in_group?(prev, curr)
      return true if prev.nil?
      return false if [prev, curr].all?(&:combined?) || [prev, curr].any?(&:formattable?)
      multiplier = prev.text.size <= 2 || curr.text.size <= 2 ? 3 : 2
      space = [prev, curr].map(&:font_width).max * multiplier
      curr.intersects_horizontally?(prev) && (curr.min_x - prev.max_x).between?(-10, space)
    end

    def spatially_group_words(words)
      grouped_words = []
      current_group = []
      words&.each do |word|
        next current_group.push(word) if combine_words_in_group?(current_group.last, word)
        grouped_words.push(combine_words_in_a_group(current_group))
        current_group = [word]
      end
      grouped_words.push(combine_words_in_a_group(current_group)) if current_group.present?
      grouped_words
    end

    def combine_words_in_a_group(words)
      return words.first if words.size == 1
      VisionWord.factory(
        'text'           => construct_phrase(words.map(&:text).map(&:to_s)),
        'bounds'         => combine_bounds(words),
        'corrected_text' => construct_phrase(words.map(&:corrected_text).map(&:to_s))
      )
    end

    def closest_value_connected_to_label(label, all_values)
      options = all_values.select { |v| label.intersects_right?(v) && label.horizontal_intersection_percent(v) > 50 }
      options.min_by { |val| val.distance_to(label) }
    end

    def values_connected_to_label(label, all_values)
      values = []
      loop do
        value = closest_value_connected_to_label(label, all_values)
        break unless value.present?
        values.push(value)
        label = value
      end
      values
    end

    def frequent_year_in(dates)
      dates = dates.map { |w| w.is_a?(VisionWord) ? w.to_date : w }.compact
      all_years = dates.map(&:year)
      frequent = all_years.max_by { |year| all_years.count(year) }
      all_years.count(frequent) >= 2 ? frequent : nil
    end
  end
end
