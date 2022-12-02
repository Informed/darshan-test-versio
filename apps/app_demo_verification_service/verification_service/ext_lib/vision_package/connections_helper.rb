module VisionPackage
  module ConnectionsHelper
    def axis(direction)
      direction.to_sym.in?(%i[top bottom]) ? :vertical : :horizontal
    end

    def within_horizontal_threshold?(word1, word2)
      VisionWord.horizontal_gap(word1, word2) <= word1.font_width * 200 # Just for sanity
    end

    def within_vertical_threshold?(word1, word2)
      VisionWord.vertical_gap(word1, word2) <= word1.font_height * 5
    end

    def valid_connection?(word, conn, direction)
      conn.present? &&
        send("within_#{axis(direction)}_threshold?", word, conn) &&
        (conn.formattable?(strict: false) || direction.to_s.in?(%w[top left])) &&
        !(word.date? && conn.formattable? && !conn.date?)
    end

    def connection_options(word, all_words, direction)
      axis = axis(direction)
      # TODO: These limits should be something that can be passed in as config.
      all_words.select do |w|
        w1, w2 = [word, w].sort_by(&:length)
        threshold = axis == :horizontal ? 35 : 10
        font_ratio = [w1, w2].all?(&:formattable?) ? 1.5 : 2
        word.send("intersects_#{direction}?", w) &&
          [w1.send("#{axis}_intersection_percent", w2), w2.send("#{axis}_intersection_percent", w1)].compact.select(&:finite?).max.to_i >= threshold && # rubocop:disable Layout/LineLength
          w1.font_height.fdiv(w2.font_height).between?(1.fdiv(font_ratio), font_ratio) &&
          (axis == :vertical || VisionWord.send("#{axis}_gap", word, w) >= -1 * word.font_width)
      end
    end

    def horizontal_connection_option(word, options)
      closest = options.min_by { |option| VisionWord.horizontal_gap(option, word) }
      return unless closest.present?
      options = [closest] + (options - [closest]).select { |option| option.intersects_vertically?(closest) }
      options.max_by { |option| word.horizontal_intersection_percent(option) }
    end

    def vertical_connection_option(word, options)
      options.min_by { |option| VisionWord.send(:vertical_gap, option, word) }
    end

    def closest_connection(word, all_words, direction)
      options = connection_options(word, all_words, direction)
      connection = send("#{axis(direction)}_connection_option", word, options)
      connection if valid_connection?(word, connection, direction)
    end

    def opposite_direction(direction)
      return :bottom if direction == :top
      return :top if direction == :bottom
      direction == :right ? :left : :right
    end

    def duplicate_connection?(word, closest, direction, connections)
      opp_conn = connections[closest].send(opposite_direction(direction))&.word
      dir_conn = connections[word].send(direction)&.word
      duplicate = (opp_conn.present? && opp_conn != word) || (dir_conn.present? && dir_conn != closest)
      return duplicate unless duplicate && Log.debug?
      context = { direction: direction, word: word.text, closest: closest.text, dir_conn: dir_conn&.text, opp_conn: opp_conn&.text } # rubocop:disable Layout/LineLength
      Log.debug("Duplicate connection: #{context}")
      duplicate
    end

    def linked?(conn1, conn2)
      DIRECTIONS.any? { |dir| conn1.send(dir)&.word == conn2.word }
    end
  end
end
