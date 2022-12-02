module BingApiHelper
  # require 'net/https'
  # require 'uri'
  # require 'json'
  include HttpHelper

  URL ||= 'https://api.cognitive.microsoft.com'.freeze

  def search_for(term)
    return [] unless ENV.key?('BING_WEB_SEARCH_KEY')

    search_cache = Caches::BingSearch.new(term.gsub(/[^a-z0-9 ]/i, '').downcase)
    cache_result = search_cache.fetch
    return JSON.parse(cache_result) unless cache_result.nil?

    headers = { 'Ocp-Apim-Subscription-Key' => ENV.fetch('BING_WEB_SEARCH_KEY', nil) }
    response = get_json("#{URL}/bing/v7.0/search?mkt=en-us&q=#{CGI.escape(term)}", header: headers)
    result = response['webPages']['value']
    search_cache.insert(result: result.json)
    result
  rescue
    []
  end

  def spell_check(words)
    return [] unless ENV.key?('BING_SPELL_CHECK_KEY')

    spell_check_cache = Caches::BingSpellCheck.new(term.gsub(/[^a-z0-9 ]/i, '').downcase)
    cache_result = spell_check_cache.fetch
    return JSON.parse(cache_result) unless cache_result.nil?

    params = URI.encode_www_form('text': words)
    header = { 'Content-Type'              => 'application/x-www-form-urlencoded',
               'Ocp-Apim-Subscription-Key' => ENV.fetch('BING_SPELL_CHECK_KEY', nil) }
    # mode can have proof or spell, proof is more for documents
    # https://azure.microsoft.com/en-us/services/cognitive-services/spell-check/
    response = post_json("#{URL}/bing/v7.0/spellcheck?mkt=en-us&mode=proof", params: params, header: header)
    result = response['flaggedTokens']
    spell_check_cache.insert(result.to_json)
    result
  rescue
    []
  end
end
