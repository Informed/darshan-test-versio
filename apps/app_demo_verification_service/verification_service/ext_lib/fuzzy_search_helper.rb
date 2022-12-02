module FuzzySearchHelper
  def sanitize_text(text)
    return unless text.is_a?(String)
    text.gsub(/[^a-z1-9\s]/i, ' ').gsub(/\s+/, ' ').strip
  end

  def fuzzy_search(target, text)
    # the output is the string we find that is closest to the target
    target = sanitize_text(target)
    text = sanitize_text(text)
    return unless [target, text].all?
    text_parts = text.split
    target_parts_size = target.split.size
    text_parts.each_with_index do |_, index|
      start_index = [0, index - target_parts_size + 1].max
      combined_str = text_parts[start_index..index].join(' ')
      return combined_str if JaroWinkler.distance(target, combined_str, ignore_case: true) > [0.9, (1 - (target_parts_size * 0.03))].max # rubocop:disable Layout/LineLength
    end
    nil
  end

  def find_all_fuzzy_match_indexes(target, text)
    # this function will return indexes for target in text
    # need to reprocess target and text before use this function
    return [] unless [target, text].all?
    text_parts = text.split
    target_parts_size = target.split.size
    indexes = []
    count = 0
    text_parts.each_with_index do |word, index|
      start_index = index - target_parts_size + 1
      next count = count + word.size + 1 unless start_index >= 0
      combined_str = text_parts[start_index..index].join(' ')
      count = count + word.size - 1
      indexes << [count - combined_str.size + 1, count] if JaroWinkler.distance(target, combined_str, ignore_case: true) > [0.9, (1 - (target_parts_size * 0.03))].max # rubocop:disable Layout/LineLength
      count += 2
    end
    indexes
  end
end
