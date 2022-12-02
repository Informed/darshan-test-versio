require_relative 'vision_page'
require_relative 'computer_vision_data'

module VisionPackage
  class VisionDocument
    include ComputerVisionData
    attr_reader :pages, :document_type, :document_url, :dimensions, :page_width, :page_height, :forms, :sub_document_types # rubocop:disable Layout/LineLength

    DEFAULT_TEXT_CATEGORIES = %w[text corrected_text].freeze
    DEFAULT_WORD_CATEGORIES = %w[words paragraphs combined_words grouped_words unique_words].freeze

    class << self
      def payload(document_type, document_url, sub_document_types, vision_data)
        VisionDocument.new(document_type, document_url, sub_document_types, vision_data).to_payload
      end

      def from_partial_vision_document(vision_document, included_pages, document_type = nil)
        return vision_document if included_pages.blank?
        pages = vision_document.pages.values_at(*included_pages)
        # TODO: document_url is definitely incorrect. Maybe it should use the recombine function
        new(document_type, vision_document.document_url, vision_document.sub_document_types, pages)
      end

      def from_payload(payload)
        new(payload['document_type'], payload['document_url'], payload['sub_document_types'], payload['vision_data'])
      end
    end

    # pages_data is an array of maps of pages of ocr data, e.g. { page_url: ..., ocr_data: {} }
    def initialize(document_type, document_url, sub_document_types, pages_data)
      @document_type = document_type&.to_sym || :unknown
      @document_url = document_url
      @sub_document_types = sub_document_types
      @pages = (pages_data || []).map { |page| VisionPage.factory(page) }
      @forms = pages.flat_map(&:forms).compact
      @dimensions = { height: pages.sum(&:page_height), width: pages.first&.page_width }.with_indifferent_access
      @page_width = dimensions[:width]
      @page_height = dimensions[:height]
    end

    def merged_data
      process_words
      @merged_data ||= {}
      return @merged_data unless @merged_data.empty?
      ex_pages = ((!defined?(@include_pages) || @include_pages.nil?) ? pages : pages.values_at(*@include_pages)).compact
      return @merged_data unless ex_pages.any? { |page| !page.document_text&.text&.blank? || !page.text&.text&.blank? }
      @merged_data['document_text'] = combined_hash('document_text', ex_pages)
      @merged_data['text'] = combined_hash('text', ex_pages)
      @merged_data
    end

    def combined_hash(source, ex_pages)
      ex_pages ||= pages
      pages_with_source = ex_pages.flat_map { |page| page.respond_to?(source) ? page.send(source) : nil }.compact
      hash_result = {}
      return hash_result unless pages_with_source.present?
      offsets = vertical_offsets(ex_pages)
      DEFAULT_TEXT_CATEGORIES.each { |cat| hash_result[cat] = combine_pages(pages_with_source, cat, offsets, nil) }
      DEFAULT_WORD_CATEGORIES.each { |cat| hash_result[cat] = combine_pages(pages_with_source, cat, offsets) }
      GvaWrapper::COMBINED_CATEGORIES.each { |cat| hash_result[cat] = combine_pages(pages_with_source, cat, offsets) }
      hash_result
    end

    def process_words(options = {})
      force = options.fetch(:force, false)

      return if @processed && !force
      @processed = true
      pages.each { |page| page.process_words(document_type) }
    end

    def to_payload
      {
        document_type:      document_type,
        document_url:       document_url,
        sub_document_types: sub_document_types,
        vision_data:        pages&.map(&:to_payload) || []
      }
    end

    def include_pages(indices)
      return if indices&.sort == @include_pages&.sort
      @merged_data = nil
      @dollar_words = nil
      @connected_words = nil
      @find_all_dates = nil
      @include_pages = indices&.compact
    end

    def tables
      return @tables if defined?(@tables)
      offsets = vertical_offsets
      @tables = pages.flat_map.with_index { |page, index| page.tables(offsets[index], document_type) }
    end

    def signatures
      return @signatures if defined?(@signatures)
      offsets = vertical_offsets
      @signatures = pages.flat_map.with_index { |page, index| page.signatures(offsets[index]) }
    end

    def checkboxes
      return @checkboxes if defined?(@checkboxes)
      offsets = vertical_offsets
      @checkboxes = pages.flat_map.with_index { |page, index| page.checkboxes(offsets[index]) }
    end

    def redactions
      return @redactions if defined?(@redactions)
      offsets = vertical_offsets
      @redactions = pages.flat_map.with_index do |page, index|
        page.redactions(offsets[index]).map do |bound|
          VisionPackage::VisionBox.factory(bound, ocr_words)
        end
      end
    end

    def vertical_offsets(pgs = nil)
      y_offsets((pgs || pages).map(&:page_height))
    end

    def image_blocks
      @image_blocks ||= {}
      return @image_blocks if @image_blocks.present?
      page_blocks = pages.map { |p| p.image_blocks&.with_indifferent_access }.compact
      offsets = vertical_offsets(pages)
      @image_blocks = {
        'selected'      => page_blocks.map { |doc| doc['selected'] }.compact.flatten || [],
        'with_lines'    => combine_image_blocks(page_blocks, 'with_lines', offsets),
        'with_polygons' => combine_image_blocks(page_blocks, 'with_polygons', offsets)
      }
    end

    def combine_image_blocks(page_blocks, source, offsets)
      {
        'words'  => page_blocks.map.with_index do |pb, idx|
                      augment_words(pb.dig(source, 'words'), offsets[idx])
                    end.compact.flatten || [],
        'blocks' => page_blocks.map.with_index do |pb, idx|
                      pb.dig(source, 'blocks')&.map do |k, v|
                        bnds = Bounds.factory(v['points'])
                        bnds.add_y_offset(offsets[idx])
                        [
                          "#{idx}_#{k}",
                          {
                            'words'     => augment_words(v['words'], offsets[idx]),
                            'full_text' => v['full_text'],
                            'id'        => k,
                            'points'    => bnds.to_points
                          }
                        ]
                      end.to_h
                    end.compact.reduce(&:merge) || {}
      }.with_indifferent_access
    end

    def combine_pages(pages, key, offsets, default = [])
      pages.map.with_index do |page, idx|
        value = page.respond_to?(key) ? page.send(key) : default
        value.is_a?(Array) ? augment_words(value, offsets[idx]) : value
      end.compact.reduce(&:+)
    end

    def augment_words(words, offset)
      words&.map { |word| VisionWord.deep_clone(VisionWord.factory(word)) }&.each { |word| word.bounds.add_y_offset(offset) } # rubocop:disable Layout/LineLength
    end

    def cache_key
      hash + @include_pages.hash
    end

    def inspect
      "DocumentType:#{document_type}"
    end
  end
end
