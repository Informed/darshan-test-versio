require_relative 'connections_helper'
module VisionPackage
  class ConnectedWord
    extend ConnectionsHelper
    attr_reader :word, :left, :right, :top, :bottom

    DIRECTIONS ||= %i[left right top bottom].freeze

    class << self
      def create_from_document(document, src = GvaWrapper::DOCUMENT_TEXT)
        create_connections(all_connection_words(document, src), document.value_words(src))
      end

      def create_connections(all_words, value_words, options = {})
        avoid_duplicate = options.fetch(:avoid_duplicate, true)

        connections = {}
        value_words.each do |word|
          connections[word] ||= ConnectedWord.new(word)
          ConnectedWord::DIRECTIONS.each do |direction|
            closest = closest_connection(word, all_words, direction)
            next unless closest.present?
            connections[closest] ||= ConnectedWord.new(closest)
            next if avoid_duplicate && duplicate_connection?(word, closest, direction, connections)
            connections[word].instance_variable_set("@#{direction}", connections[closest])
            connections[closest].instance_variable_set("@#{opposite_direction(direction)}", connections[word])
          end
        end
        connections
      end

      def left_closest_connection(word, document, src = GvaWrapper::DOCUMENT_TEXT)
        # Should cache this as well as the value might be used multiple times
        closest_connection(word, all_connection_words(document, src), :left)
      end

      def top_closest_connection(word, document, src = GvaWrapper::DOCUMENT_TEXT)
        # Should cache this as well as the value might be used multiple times
        closest_connection(word, all_connection_words(document, src), :top)
      end

      def all_connection_words(doc, src = GvaWrapper::DOCUMENT_TEXT)
        doc.grouped_words(src).select { |w| w.formattable?(strict: false) || (w.match?(/[a-z].*[a-z]/i) && !blacklisted_label?(w, doc)) } # rubocop:disable Layout/LineLength
      end

      def blacklisted_label?(w, doc)
        return false unless doc.document_type.to_sym == :paystub
        w.match?(/^(yes|no)$/i)
      end
    end

    def initialize(word)
      @word = word
      DIRECTIONS.each do |direction|
        self.class.send(:define_method, "#{direction}_connections") { direction_connections(direction) }
        self.class.send(:define_method, "#{direction}_words") { direction_connections(direction).map(&:word) }
      end
    end

    def direction_connections(dir)
      @direction_connections ||= {}
      @direction_connections[dir] ||= send(dir).present? ? [send(dir)] + send(dir).direction_connections(dir) : []
    end

    def vertical_words
      ([word] + top_words + bottom_words).uniq.sort_by(&:min_y)
    end

    def horizontal_words
      ([word] + left_words + right_words).uniq.sort_by(&:min_x)
    end

    def top_label
      top_most = top_words.min_by(&:min_y)
      top_most if top_most.present? && !top_most.formattable?
    end

    def left_label
      left_most = left_words.min_by(&:min_x)
      left_most if left_most.present? && !left_most.formattable?
    end

    def to_h
      DIRECTIONS.to_h { |direction| [direction, send(direction)&.word] }
    end

    alias inspect to_h
  end
end
