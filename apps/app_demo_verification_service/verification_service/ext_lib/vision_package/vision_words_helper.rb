module VisionPackage
  module VisionWordsHelper
    def self.included(base)
      base.extend(VisionWordsHelperMethods)
      base.include(VisionWordsHelperMethods)
    end

    module VisionWordsHelperMethods
      def minmax_x(words)
        objectify(words).map(&:x_coords).flatten.minmax
      end

      def minmax_y(words)
        objectify(words).map(&:y_coords).flatten.minmax
      end

      def minmax(words, coord)
        send("minmax_#{coord}", words)
      end

      def min_x(words)
        minmax_x(words).first
      end

      def max_x(words)
        minmax_x(words).last
      end

      def min_y(words)
        minmax_y(words).first
      end

      def max_y(words)
        minmax_y(words).last
      end

      def combine_bounds(words, options = {})
        hash = options.fetch(:hash, true)

        x0, x1 = minmax_x(words)
        y0, y1 = minmax_y(words)
        bounds = Bounds.factory([[x0, y0], [x1, y0], [x1, y1], [x0, y1]])
        hash ? bounds.to_h : bounds
      end

      def angle_across(words)
        angles = objectify(words).map { |word| word.angle.to_i }.compact
        angles.max_by { |angle| angles.count(angle) }
      end

      def words_connected_on_slope(source, words, tolerance = nil)
        objectify(words).select { |word| word == source || source.connected_on_slope?(word, tolerance) }
      end

      def words_connected_horizontally(source, words, tolerance = nil)
        objectify(words).select { |word| source.connected_horizontally?(word, tolerance) }
      end

      def words_connected_vertically(source, words, tolerance = nil)
        objectify(words).select { |word| source.connected_vertically?(word, tolerance) }
      end

      def any_connected_horizontally?(source, words, tolerance = nil)
        words_connected_horizontally(source, words, tolerance).present?
      end

      def any_connected_vertically?(source, words, tolerance = nil)
        words_connected_vertically(source, words, tolerance).present?
      end

      def words_intersecting_horizontally(source, words, tolerance = nil)
        objectify(words).select { |word| source.intersects_horizontally?(word, tolerance) }
      end

      def words_intersecting_vertically(source, words, tolerance = nil)
        objectify(words).select { |word| source.intersects_vertically?(word, tolerance) }
      end

      def find_horizontally(source, words)
        words_intersecting_horizontally(source, words).max_by { |word| source.horizontal_intersection_percent(word) }
      end

      def find_vertically(source, words)
        centroid = source.centroid
        connected_words = objectify(words).select { |word| word.min_x < centroid.x && centroid.x < word.max_x }
        closest_pair([source], connected_words)&.second
      end

      # Given 2 arrays of words, find a pair (1 from each array) that are closest to each other
      def closest_pair(words1, words2)
        words1, words2 = [words1, words2].map { |words| objectify(words) }
        closest = nil
        words1.each do |word1|
          words2.each do |word2|
            dist = word1.distance_to(word2)
            closest = { pair: [word1, word2], distance: dist } unless closest.present? && closest[:distance] < dist
          end
        end
        closest[:pair] if closest
      end

      # Picks a word from each list of words such that the chosen words are ordered in a given orientation
      def find_closest_ordered_orientation(words, orientation)
        matches = words[0].map { |w| Array.wrap(w) }
        words.from(1).each_with_index do |words_item, i|
          matches.each_with_index do |match_arr, match_index|
            connected_words = words_connected_by_orientation(match_arr[-1], words_item, orientation)
            next unless connected_words.present?
            closest_connected_pair = closest_pair([match_arr[-1]], connected_words)
            matches[match_index] << closest_connected_pair.second if %i[right left].include?(orientation) || match_arr[-1].distance_to(closest_connected_pair.second) < 10 * match_arr[-1].font_height # rubocop:disable Layout/LineLength
          end
          matches = matches.select { |item| item.count == i + 2 }
        end
        matches.min_by { |items| items[0].distance_to(items[-1]) }
      end

      def words_connected_by_orientation(source, words, orientation, tolerance = nil)
        # word is in orientation to source (:bottom indicates source is on top)
        connected_fn = %i[top bottom].include?(orientation) ? :vertical : :horizontal
        objectify(words).select { |word| source.send("intersects_#{connected_fn}ly?", word, tolerance) && source.relative_position(word).include?(orientation) } # rubocop:disable Layout/LineLength
      end

      # Please don't use this function outside this module
      def objectify(words)
        words.is_a?(Array) ? words : [words]
      end
    end
  end
end
