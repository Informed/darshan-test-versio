module Caches
  class BingSearch < BaseCache
    attr_reader :employer_name

    def initialize(employer_name)
      @employer_name = employer_name
    end

    def primary_key
      TABLE.primary_key(:PK, employer_name, :SK, :bing_search)
    end
  end
end
