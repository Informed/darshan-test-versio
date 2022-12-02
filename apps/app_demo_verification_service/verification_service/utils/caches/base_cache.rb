module Caches
  class BaseCache
    TABLE ||= VerificationServiceTable
    TABLE_INSTANCE ||= TABLE.instance
    CLEAN_REGEX ||= /[^a-z0-9 ]/i.freeze

    def primary_key
      raise NotImplementedError
    end

    def insert(item, versioned: false)
      full_item = primary_key.merge(**item)
      TABLE_INSTANCE.insert(full_item, versioned: versioned)
    end

    def fetch
      TABLE_INSTANCE.fetch(primary_key, 'result')
    end

    def clean(string)
      string.gsub(CLEAN_REGEX, '').squeeze(' ').strip.downcase
    end
  end
end
