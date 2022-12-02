module PartnerProfileCache
  USABLE_CACHE_TIME ||= 5.minutes
  MAXIMUM_CACHE_STORE_SIZE ||= 40

  # Add a small caching layer at class level
  def self.cache_store(reset: false)
    return @@configs = {} if reset
    @@configs ||= {}
  end

  def self.from_cache(key, namespace)
    config_details = cache_store[key]
    return unless config_details.present?
    config_details[namespace] if (Time.now - config_details[:stored_at]) < USABLE_CACHE_TIME
  rescue => e
    Honeybadger.notify(e, context: { key: key }, tags: 'low_priority')
    nil
  end

  def self.to_cache(key, config_result)
    # want to make sure we don't run into any memory leak
    # This is the prelimiary approach, we can always add smarter logic if needed
    # if the entries exceeds the limit, we just purge them and start from scratch again
    if cache_store.size > MAXIMUM_CACHE_STORE_SIZE || (cache_store.size == MAXIMUM_CACHE_STORE_SIZE && !cache_store[key].present?) # rubocop:disable Layout/LineLength
      cache_store(reset: true)
    end
    cache_store[key] = {
      stored_at:                       Time.now,
      metadata:                        config_result['metadata'],
      stipulation_verification_config:   config_result['stipulationVerificationConfig'], # rubocop:disable Layout/HashAlignment
      stipulations:                    config_result.dig('stipulationVerificationConfig', 'rules', 'stipulations'),
      collect_iq:                      config_result['collectIq']
    }
  rescue => e
    Honeybadger.notify(e, context: { key: key }, tags: 'low_priority')
    nil
  end
end
