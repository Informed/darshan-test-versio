require_relative 'vision_page_source'
require_relative 'computer_vision_data'
require_relative 'vision_table'
require_relative 'textract_wrapper'

module VisionPackage
  class VisionPage
    include ComputerVisionData
    include TextractWrapper

    attr_reader :document_text, :text, :page_url, :page_height, :page_width, :forms, :image_blocks, :dimensions, :aws_ocr # rubocop:disable Layout/LineLength

    class << self
      def factory(page)
        page.is_a?(VisionPage) ? page : new(page)
      end

      def from_cropped_vision_document(vision_document, crop_data, page_url)
        bounds = Bounds.from_crop_params(crop_data)
        page_data = vision_document.merged_data.map { |k, v| crop_page_source_data(k, v, bounds) }.compact.to_h
        new(page_data.merge('page_url' => page_url, 'dimensions' => bounds.dimensions))
      end

      def crop_page_source_data(key, data, bounds)
        return unless data.present?
        vision_data = data.map { |k, v| [k, v.select { |w| bounds.contains?(w) }] if v.is_a?(Array) && v.first.is_a?(VisionWord) }.compact.to_h # rubocop:disable Layout/LineLength
        vision_data = vision_data.merge(
          'text'             => vision_data['words']&.map(&:text)&.join(' ').to_s,
          'corrected_text'   => vision_data['words']&.map(&:corrected_text)&.join(' ').to_s,
          'combined_indices' => vision_data['combined_words']&.flat_map(&:combined_indices)
        )
        [key, vision_data]
      end
    end

    def initialize(page_data)
      @page_url = page_data['page_url']
      @document_text = VisionPageSource.new(:document_text, page_data['document_text']) if page_data.key?('document_text') # rubocop:disable Layout/LineLength
      @text = VisionPageSource.new(:text, page_data['text']) if page_data.key?('text')
      @raw_tables = page_data['tables']
      @image_blocks = page_data['image_blocks'] || {}
      @forms = page_data['forms']
      @aws_ocr = page_data['aws_ocr']
      @dimensions = page_data['dimensions'] || {}
      @page_height = dimensions['height'] || 0
      @page_width = dimensions['width'] || 0
      @raw_signatures = page_data['signatures'] || []
      @raw_checkboxes = page_data['checkboxes'] || []
      @raw_redactions = page_data['redactions'] || []
    end

    def correct_spelling
      raise NotImplementedError # Not sure we need to do this here, I think it's probably fine to assume API will do it
    end

    def signatures(y_offset = 0)
      @signatures ||= {}
      @signatures[y_offset] ||= @raw_signatures.map do |b|
        bnd = VisionPackage::Bounds.from_crop_params(b['bounding_box'])
        bnd.add_y_offset(y_offset)
        bnd
      end
    end

    def checkboxes(y_offset = 0)
      @checkboxes ||= {}
      @checkboxes[y_offset] ||= @raw_checkboxes.map do |b|
        bnd = VisionPackage::Bounds.from_crop_params(b['bounding_box'])
        bnd.add_y_offset(y_offset)
        bnd
      end
    end

    def redactions(y_offset = 0)
      @redactions ||= {}
      @redactions[y_offset] ||= @raw_redactions.map do |b|
        bnd = VisionPackage::Bounds.from_crop_params(b['bounding_box'])
        bnd.add_y_offset(y_offset)
        bnd
      end
    end

    def tables(y_offset = 0, document_type = nil)
      @tables ||= {}
      @tables[y_offset] ||= @raw_tables.compact.map do |tbl|
        offset = document_type.to_s == 'bank_statement' ? 0 : y_offset
        table = VisionTable.new(tbl, grouped_words, y_offset: offset)
        document_type.to_s == 'bank_statement' ? complete_table_rows(table, grouped_words, y_offset) : table
      end
    end

    def merged_data
      process_words
      @merged_data ||= {}
      return @merged_data unless @merged_data.empty?
      @merged_data['document_text'] = document_text&.merged_data unless document_text.nil?
      @merged_data['text'] = text&.merged_data unless text.nil?
      @merged_data
    end

    def process_words(document_type = nil)
      document_type ||= 'unknown'
      document_text&.process_words(document_type)
      text&.process_words(document_type)
    end

    def to_payload
      vision_data = {}
      vision_data[:document_text] = document_text&.to_payload unless document_text.nil?
      vision_data[:text] = text&.to_payload unless text.nil?
      vision_data.merge(
        page_url:     page_url,
        dimensions:   {
          height: page_height,
          width:  page_width
        },
        forms:        forms,
        aws_ocr:      aws_ocr,
        tables:       @raw_tables,
        image_blocks: image_blocks,
        signatures:   @raw_signatures,
        checkboxes:   @raw_checkboxes,
        redactions:   @raw_redactions
      )
    end

    alias cache_key hash
  end
end
