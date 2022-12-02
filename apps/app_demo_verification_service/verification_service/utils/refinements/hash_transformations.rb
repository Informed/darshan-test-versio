module Refinements
  module HashTransformations
    refine Hash do
      def sort_by_key(recursive = false, &block)
        keys.sort(&block).each_with_object({}) do |key, seed|
          seed[key] = self[key]
          seed[key] = seed[key].sort if seed[key].is_a?(Array)
          seed[key] = seed[key].sort_by_key(true, &block) if recursive && seed[key].is_a?(Hash)
        end
      end

      def camelize_keys!
        update_keys!(:camelize, :lower)
      end

      def underscore_keys!
        update_keys!(:underscore)
      end

      def downcase_keys!
        update_keys!(:downcase)
      end

      def update_keys!(method, *args)
        each_key do |key|
          updated_key = key.to_s.send(method, *args).to_sym
          self[updated_key] = delete(key)
          self[updated_key].update_keys!(method, *args) if self[updated_key].is_a?(Hash)
        end
        self
      end

      def underscore_keys(drop_nil = false, retain_spaces = false, options = {})
        skip_regex = options.fetch(:skip_regex, nil)

        convert_hash_keys(self, ->(key) { (retain_spaces && key.to_s.match?(/\s/)) || (skip_regex && key.to_s.match?(skip_regex)) ? key : key.to_s.underscore.to_sym }, drop_nil) # rubocop:disable Layout/LineLength
      end

      def camelize_keys(drop_nil = false, uppercase_first_letter: true)
        first_letter_case = uppercase_first_letter ? :upper : :lower
        convert_hash_keys(self, ->(key) { key.to_s.camelize(first_letter_case) }, drop_nil)
      end

      def camelize_lower_stringify_keys(drop_nil = false, retain_spaces = false)
        convert_hash_keys(self, ->(key) { retain_spaces && key.to_s.match?(/\s/) ? key : key.to_s.camelize(:lower).to_s }, drop_nil) # rubocop:disable Layout/LineLength
      end

      def downcase_keys(drop_nil = false)
        convert_hash_keys(self, ->(key) { key.downcase }, drop_nil)
      end

      # input_hash: { a: [{b: c}, {d: e}], f: {g: h} }
      # output_hash: {"a.0.b"=>c, "a.1.d"=>e, "f.g"=>h}
      def flatten_keys(drop_nil = false)
        each_with_object({}) do |(k, v), h|
          case v
          when Hash
            flatten_keys_helper(k, h, v.flatten_keys(drop_nil))
          when Array
            flatten_keys_helper(k, h, convert_array_to_indexed_hash(v).flatten_keys(drop_nil))
          else
            h[k.to_s] = v unless drop_nil && value.nil?
          end
        end
      end

      def convert_array_to_indexed_hash(array)
        array.each_with_object({}).with_index do |(val, h), index|
          h[index.to_s] = val
        end
      end

      def flatten_keys_helper(k, outer_hash, inner_hash)
        inner_hash.each do |inner_k, inner_v|
          outer_hash["#{k}.#{inner_k}"] = inner_v
        end
      end

      # Converts key of the hash with the key_op function
      def convert_hash_keys(value, key_op, drop_nil = false)
        case value
        when Array
          value.map { |v| convert_hash_keys(v, key_op) }
        when Hash
          h = value.to_h { |k, v| [key_op.call(k), convert_hash_keys(v, key_op, drop_nil)] }
          h.compact! if drop_nil
          h
        else
          value
        end
      end

      # Converts value of the hash with the val_op function
      def convert_hash_values(value, val_op)
        case value
        when Array
          value.map { |v| convert_hash_values(v, val_op) }
        when Hash
          value.transform_values { |v| convert_hash_values(v, val_op) }
        else
          val_op.call(value) if value.present?
        end
      end

      def convert_values(val_op)
        convert_hash_values(self, val_op)
      end

      def strip_strings(replace_empty = true)
        convert_hash_values(self, ->(val) { val.blank? && replace_empty ? nil : val.strip })
      end

      def stringify_nils
        transform_values { |value| stringify_nil(value) }
      end

      def stringify_nil(value)
        if value.is_a? Hash
          value.stringify_nils
        else
          value.nil? ? '' : value
        end
      end

      def nil_hash_values
        transform_values { |value| value.is_a?(Hash) ? value.nil_hash_values : nil }
      end

      def lossless_invert
        each_with_object({}) { |(k, v), o| (v.is_a?(Array) ? v : [v]).each { |val| (o[val] ||= []) << k } }
      end
    end
  end
end
