module Caches
  class NameMatch < BaseCache
    attr_reader :employer_name, :compare_name

    def initialize(employer_name, compare_name)
      @employer_name = employer_name
      @compare_name = compare_name
    end

    def primary_key
      TABLE.primary_key(:PK, "#{clean(employer_name)}:#{clean(compare_name)}", :SK, :name_match)
    end
  end
end
