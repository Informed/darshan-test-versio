require_relative 'vision_words_helper'

module VisionPackage
  module TextractWrapper
    include VisionPackage::VisionWordsHelper

    def complete_table_rows(table, grouped_words, y_offset = 0)
      return table if table.rows.blank?
      rows = table.rows.to_h { |idx, row| [idx, complete_row(row, idx, grouped_words)] }
      rows = complete_missing_rows(rows, grouped_words)
      VisionPackage::VisionTable.from_rows(rows, grouped_words, y_offset: y_offset)
    end

    def complete_row(row, row_id, words)
      return if row.blank?
      bounds = combine_bounds(row.map(&:bounds), hash: false)
      new_row = ([hor_cell_words(words, bounds, row, row_id)] + row + [hor_cell_words(words, bounds, row, row_id, :right)]).compact # rubocop:disable Layout/LineLength
      new_row.each_with_index { |cell, idx| cell.col_id = idx + 1 }
    end

    def hor_cell_words(words, bounds, row, row_id, direction = :left)
      cell_words = words.select { |word| bounds.intersects_horizontally?(word) && word.send("#{direction}?", adjusted_row_bounds(row, bounds)) } # rubocop:disable Layout/LineLength
      VisionPackage::VisionCell.from_words(row_id, nil, cell_words, words, bounds: cell_bounds(cell_words, bounds, direction)) if cell_words.present? # rubocop:disable Layout/LineLength
    end

    def adjusted_row_bounds(row, bounds)
      return combine_bounds(row[1..row.length - 1].map(&:bounds), hash: false) if row.first.text.nil? && row.last.text.nil? # rubocop:disable Layout/LineLength
      return combine_bounds(row[1..row.length].map(&:bounds), hash: false) if row.first.text.nil?
      row.last.text.nil? ? combine_bounds(row[0..row.length - 1].map(&:bounds), hash: false) : bounds
    end

    def cell_bounds(cell_words, bounds, direction)
      section = direction == :right ? [bounds.max_x, bounds.min_y, cell_words.map(&:max_x).max, bounds.max_y] : [cell_words.map(&:min_x).min, bounds.min_y, bounds.min_x, bounds.max_y] # rubocop:disable Layout/LineLength
      VisionPackage::Bounds.from_section(section)
    end

    def complete_missing_rows(rows, grouped_words)
      tmp_rows = rows.values.compact
      tmp_rows = missing_row(tmp_rows.first, grouped_words, :top) + tmp_rows + missing_row(tmp_rows.last, grouped_words)
      tmp_rows.each_with_index do |row, row_idx|
        row.each_with_index do |cell, col_idx|
          cell.col_id = col_idx + 1
          cell.row_id = row_idx + 1
        end
      end
      tmp_rows.to_h { |row| [row.map(&:row_id).last, row] }
    end

    def missing_row(row, grouped_words, direction = :bottom)
      rows = [row]
      y_multiplier = direction == :bottom ? 1 : -1
      loop do
        row = y_multiplier.positive? ? rows.last : rows.first
        break if row.blank?
        new_row = cell_words_from_rows(row, grouped_words, y_multiplier) ||
                  cell_words_from_connected_words(row, grouped_words, y_multiplier)
        break if new_row.blank?
        rows = y_multiplier.positive? ? rows << new_row : [new_row] + rows
      end
      rows - row
    end

    def cell_words_from_connected_words(row, grouped_words, y_multiplier)
      return if row.blank?
      words_in_row = row.flat_map(&:words).compact
      direction = y_multiplier.positive? ? :bottom : :top
      date_dollar = [words_in_row.find(&:date?), words_in_row.find(&:dollar?)]
      return if date_dollar.any?(&:blank?)
      connections = date_dollar.map { |w| send("word_#{direction}", w, grouped_words) }
      return if connections.any?(&:blank?) || !connections.all? { |w| w&.dollar? || w&.date? }
      return unless connections.first.intersects_right?(connections.last)
      y_offset = y_multiplier.positive? ? connections.map(&:max_y).max - date_dollar.map(&:max_y).max : date_dollar.map(&:min_y).min - connections.map(&:min_y).min # rubocop:disable Layout/LineLength
      cell_words_from_rows(row, grouped_words, y_multiplier, y_offset: y_offset)
    end

    def cell_words_from_rows(row, grouped_words, y_multiplier, options = {})
      y_offset = options.fetch(:y_offset, nil)
      return if row.blank?

      max_font_height = row.flat_map(&:words).compact.map(&:font_height)&.max || 20
      bounds = row.map { |cell| cell.bounds.deep_clone }
      bounds.each { |bound| bound.add_y_offset(y_multiplier * (y_offset || bound.height)) }
      cell_words = bounds.map { |bound| grouped_words.select { |w| bound.contains_centroid?(w) && w.font_height < 1.2 * max_font_height } } # rubocop:disable Layout/LineLength
      return unless cell_words.all?(&:present?) || [cell_words.flatten.any?(&:date?), cell_words.flatten.any?(&:dollar?)].all? # rubocop:disable Layout/LineLength
      cell_words.map.with_index do |words, idx|
        words = [VisionWord.factory('text' => '', 'bounds' => bounds[idx])] if words.blank?
        VisionPackage::VisionCell.from_words(nil, nil, words, grouped_words, bounds: bounds[idx])
      end
    end

    def word_bottom(word, all_words)
      all_words.select { |w| word.intersects_bottom?(w) }&.min_by(&:min_y)
    end

    def word_top(word, all_words)
      all_words.select { |w| word.intersects_top?(w) }&.max_by(&:min_y)
    end
  end
end
