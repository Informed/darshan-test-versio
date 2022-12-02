module VisionPackage
  module Refinements
    module HashExtensions
      refine Hash do
        def array_merge(other)
          copy = dup
          other.each do |key, val|
            copy[key] ||= []
            copy[key].append(*val)
          end
          copy
        end
      end
    end
  end
end
