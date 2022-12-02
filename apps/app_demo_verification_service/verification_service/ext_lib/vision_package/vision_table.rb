require_relative 'vision_cell'
require_relative 'bounds'
require_relative 'vision_words_helper'

module VisionPackage
  class VisionTable
    include VisionWordsHelper
    attr_reader :cells, :bounds, :rows

    class << self
      def from_rows(rows, all_words, options = {})
        y_offset = options.fetch(:y_offset, 0)

        bounds = combine_bounds(rows.values.flatten.map(&:bounds), hash: false)
        new_rows = rows.to_h { |idx, row| [idx.to_s, { 'cells' => sanitize_row(row) }] }
        new({ 'bounds' => bounds, 'rows' => new_rows }, all_words, y_offset: y_offset)
      end

      def sanitize_row(row)
        row.to_h { |cell| [cell.col_id.to_s, { 'text' => cell.text, 'bounds' => cell.bounds }] }
      end
    end

    def initialize(table, all_words, options = {})
      y_offset = options.fetch(:y_offset, 0)

      @cells = []
      @rows = {}
      @bounds = Bounds.factory(table['bounds'])
      @bounds.add_y_offset(y_offset)
      visionize_cells(table, all_words, y_offset)
    end

    def find_cells_with_text(text_regex)
      text_regex = /#{text_regex}/i unless text_regex.is_a?(Regexp)
      cells.select { |cell| cell.text_match?(text_regex) }
    end

    def find_cell_by_position(row_idx, col_idx)
      cells.find { |cell| cell.row_id == row_idx && cell.col_id == col_idx }
    end

    def find_row_by_position(row_idx)
      rows[row_idx]
    end

    def size
      @size ||= [rows.keys.size, rows.values.first.size]
    end

    private

    def visionize_cells(table, all_words, y_offset)
      table['rows'].each do |row_idx, row|
        rows[row_idx.to_i] ||= []
        row['cells'].each do |col_idx, cell|
          vision_cell = VisionCell.new(row_idx, col_idx, cell, all_words, y_offset: y_offset)
          cells.append(vision_cell)
          rows[row_idx.to_i].append(vision_cell)
        end
      end
    end
  end
end
