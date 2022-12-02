require_relative 'gva_wrapper'
require_relative 'vision_word'

module VisionPackage
  class VisionPageSource
    # SPECIFICALLY reader, I don't want callers modifying data here
    attr_reader :source, :text, :words, :bounds, :corrected_text, :grouped_words, :combined_words, :combined_indices,
                :corrected_spelling_map, :paragraphs

    WORD_CATEGORIES ||= %w[words combined_words grouped_words].append(*GvaWrapper::COMBINED_CATEGORIES)

    def initialize(source, page_source_data)
      @source = source
      @text = page_source_data['text']
      @corrected_text = page_source_data['corrected_text']
      @words = VisionWord.factory(page_source_data['words'])
      @bounds = page_source_data['bounds']
      @paragraphs = VisionWord.factory(page_source_data['paragraphs']) || []
      @combined_words = VisionWord.factory(page_source_data['combined_words']) || []
      @combined_indices = page_source_data['combined_indices'] || []
      GvaWrapper::COMBINED_CATEGORIES.each do |cat|
        self.class.define_method(cat) do
          page_source_data[cat] || []
        end
      end
    end

    def unique_words
      return @unique_words if defined?(@unique_words)
      return @unique_words = (words || []).dup if combined_words.blank?
      indexed_combined_words = combined_words.map { |word| word.merge(index: word.combined_indices&.min) }
      words_list = words.map.with_index { |word, index| word.merge(index: index) } || []
      words_list = words_list.reject { |word| combined_indices.include?(word[:index]) }
      unique_words = words_list + indexed_combined_words
      @unique_words = combined_indices.present? ? unique_words.sort_by { |a| a[:index] } : unique_words
    end

    def process_words(document_type)
      return if words.nil? || words.empty?
      reset_data
      recombine_words(document_type)
      regroup_words
    end

    def respond_to_missing?(method_name, *_args, &_block)
      GvaWrapper::COMBINED_CATEGORIES.include?(method_name.to_s)
    end

    def method_missing(method_name, *args, &block)
      return super unless GvaWrapper::COMBINED_CATEGORIES.include?(method_name.to_s)
      self.class.define_method(method_name) do
        # figure out some magic to dynamically create readers here for each category
        instance_variable_set("@#{method_name}", []) unless instance_variable_get("@#{method_name}")
        instance_variable_get("@#{method_name}")
      end
      send(method_name, *args, &block)
    end

    def merged_data
      {
        text:                   text,
        words:                  words,
        combined_words:         combined_words,
        grouped_words:          grouped_words,
        unique_words:           unique_words,
        combined_indices:       combined_indices,
        corrected_spelling_map: corrected_spelling_map,
        corrected_text:         corrected_text
      }.merge(hash_from_categories(to_payload: false)).with_indifferent_access
    end

    def to_payload
      {
        text:                   text,
        words:                  words&.map(&:to_payload),
        combined_words:         combined_words&.map(&:to_payload),
        grouped_words:          grouped_words&.map(&:to_payload),
        unique_words:           unique_words&.map(&:to_payload),
        combined_indices:       combined_indices,
        corrected_spelling_map: corrected_spelling_map,
        corrected_text:         corrected_text
      }.merge(hash_from_categories)
    end

    private

    def hash_from_categories(options = {})
      to_payload = options.fetch(:to_payload, true)

      pairs = GvaWrapper::COMBINED_CATEGORIES.map do |cat|
        res = instance_variable_get("@#{cat}")
        res = res&.map(&:to_payload) if to_payload
        [cat, res]
      end
      pairs.reject { |pair| pair[1].nil? }.to_h
    end

    def reset_data
      @combined_words = []
      @combined_indices = []
      GvaWrapper::COMBINED_CATEGORIES.each do |cat|
        instance_variable_set("@#{cat}", [])
      end
    end

    def regroup_words
      @grouped_words = GvaWrapper.group_words_from(unique_words)
    end

    def recombine_words(document_type)
      GvaWrapper.combine_words_for(self, document_type)
    end
  end
end
