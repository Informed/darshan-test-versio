require_relative 'bounds'
require_relative 'vision_word'
require_relative 'vision_words_helper'
require_relative 'document_ocr_analysis'

module VisionPackage
  class VisionBox
    include VisionWordsHelper
    include DocumentOcrAnalysis

    attr_reader :bounds, :words, :text, :sorted_words, :sorted_text

    delegate :min_x, :max_x, :min_y, :max_y, to: :bounds
    delegate_missing_to :bounds

    class << self
      def factory(bound, all_words)
        bound = Bounds.factory(bound)
        words = all_words.select { |w| bound.contains_centroid?(w) }
        VisionBox.new(bound, words)
      end

      def create_from_document(vision_document)
        box_points = vision_document.image_blocks.with_indifferent_access.dig('with_polygons', 'blocks').values.map { |b| b['points'] } # rubocop:disable Layout/LineLength
        # TODO: Update this to not be sorted_grouped_words
        all_words = vision_document.sorted_grouped_words
        return [] if all_words.blank?
        min_area = all_words.map(&:area).sort[-(all_words.length * 0.95).floor]
        box_points.map do |box|
          box = Bounds.factory(box)
          next if box.area < min_area
          vision_box = factory(box, all_words)
          vision_box unless vision_box.words.blank?
        end.compact
      end

      def merge_boxes(box1, box2)
        factory(combine_bounds([box1.bounds, box2.bounds]), (box1.words + box2.words))
      end
    end

    def initialize(bound, words)
      @bounds = bound
      @sorted_words = sort_words_horizontally(words)
      @words = words
      @sorted_text = @sorted_words.map(&:text).join(' ')
      @text = @words.sort_by(&:min_y).map(&:text).join(' ')
    end

    def to_h
      { 'bounds' => bounds, 'words' => words, 'text' => text }
    end

    alias inspect to_h
  end
end
