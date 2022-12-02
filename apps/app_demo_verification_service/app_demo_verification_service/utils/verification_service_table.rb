class VerificationServiceTable < AwsDynamoDb
  CLEAN_REGEX ||= /[^a-z0-9 ]/i.freeze

  class << self
    def bing_search_pk(employer_name)
      primary_key(:PK, employer_name, :SK, :bing_search)
    end

    def bing_spell_check_pk(employer_name)
      primary_key(:PK, employer_name, :SK, :bing_spell_check)
    end

    def aka_pk(employer_name)
      primary_key(:PK, employer_name, :SK, :aka)
    end

    def name_match_pk(employer_name, compare_name)
      primary_key(:PK, "#{clean(employer_name)}:#{clean(compare_name)}", :SK, :name_match)
    end

    def clean(string)
      string.gsub(CLEAN_REGEX, '').squeeze(' ').strip.downcase
    end

    def instance
      @@instance ||= new
    end
  end

  def initialize
    super('app-demo-verification-service')
  end
end
