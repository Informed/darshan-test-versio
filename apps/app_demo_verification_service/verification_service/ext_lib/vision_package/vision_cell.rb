require_relative 'vision_words_helper'

module VisionPackage
  class VisionCell
    include VisionWordsHelper
    attr_accessor :row_id, :col_id
    attr_reader :text, :words, :bounds

    class << self
      def from_words(row_id, col_id, words, all_words, options = {})
        y_offset = options.fetch(:y_offset, 0)
        bounds = options.fetch(:bounds, nil)

        bounds ||= combine_bounds(words, hash: false)
        cell = { 'text' => words.map(&:text).join(' ').strip, 'bounds' => bounds }
        new(row_id, col_id, cell, all_words, y_offset: y_offset)
      end
    end

    def initialize(row_id, col_id, cell, all_words, options = {})
      y_offset = options.fetch(:y_offset, 0)

      @row_id = row_id.to_i
      @col_id = col_id.to_i
      @text = cell['text']
      @bounds = Bounds.factory(cell['bounds'])
      @words = all_words.select { |word| bounds.contains_centroid?(word) }.map { |word| VisionWord.deep_clone(word) }
      add_y_offset(y_offset)
    end

    def text_match?(regex)
      text.match?(regex) if text.present?
    end

    def dollars
      @dollars ||= words.select(&:dollar?)
    end

    def dollar?
      dollars.present?
    end

    def dates
      @dates ||= (words.select(&:date?) + words.select(&:partial_date?)).uniq.sort_by(&:min_x)
    end

    def date?
      dates.present?
    end

    def hash
      [row_id, col_id, text].hash
    end

    def add_y_offset(offset)
      bounds.add_y_offset(offset)
      words.each { |word| word.add_y_offset(offset) }
    end
  end
end
