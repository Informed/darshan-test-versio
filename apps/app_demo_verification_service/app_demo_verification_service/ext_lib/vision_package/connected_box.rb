require_relative 'bounds'
require_relative 'vision_box'
require_relative 'connections_helper'

module VisionPackage
  class ConnectedBox
    extend ConnectionsHelper
    attr_reader :box, :left, :right, :top, :bottom

    DIRECTIONS ||= %i[left right top bottom].freeze

    class << self
      def generate_connections(box_points, all_words)
        connections = {}
        min_area = all_words.map(&:area).sort[-(all_words.length * 0.95).floor]
        points_word_hash = box_points.map do |b|
          w = VisionWord.factory('bounds' => b, 'text' => '')
          next if w.area < min_area
          [b, w]
        end.compact.to_h
        points_word_hash.each_key do |box|
          vision_box = VisionBox.factory(box, all_words)
          next if vision_box.words.blank?
          remaining = points_word_hash.values - [points_word_hash[box]]
          connections[vision_box] ||= ConnectedBox.new(vision_box)
          ConnectedBox::DIRECTIONS.each do |direction|
            closest = closest_connection(points_word_hash[box], remaining, direction)
            next unless closest.present?
            closest_box = VisionBox.factory(closest.bounds, all_words)
            connections[closest_box] ||= ConnectedBox.new(closest_box)
            connections[vision_box].instance_variable_set("@#{direction}", connections[closest_box])
            connections[closest_box].instance_variable_set("@#{opposite_direction(direction)}", connections[vision_box])
          end
        end
        connections.values.uniq { |b| b.box.bounds.to_h }
      end

      def create_from_document(vision_document)
        blocks = vision_document.image_blocks.with_indifferent_access.dig('with_polygons', 'blocks')
        return [] unless blocks.present?
        box_points = blocks.values.map { |b| b['points'] }
        all_words = vision_document.sorted_grouped_words
        generate_connections(box_points, all_words)
      end
    end

    def initialize(box)
      @box = box
    end
  end
end
