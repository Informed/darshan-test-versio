module Caches
  class BingSpellCheck < BaseCache
    attr_reader :employer_name

    def initialize(employer_name)
      @employer_name = employer_name
    end

    def primary_key
      TABLE.primary_key(:PK, employer_name, :SK, :bing_spell_check)
    end
  end
end
