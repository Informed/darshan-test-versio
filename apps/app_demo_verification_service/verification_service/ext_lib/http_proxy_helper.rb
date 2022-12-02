module HttpProxyHelper
  BASIC ||= 'basic'.freeze
  OAUTH ||= 'oauth'.freeze

  class Non200Error < StandardError
    attr_reader :status

    def initialize(msg, status)
      @status = status
      super(msg)
    end
  end

  class CustomFaradayError < StandardError; end

  def post_xml(url, body, options = {})
    basic_auth = options.fetch(:basic_auth, nil)
    extra_headers = options.fetch(:extra_headers, {})
    raise_if_not_success = options.fetch(:raise_if_not_success, false)

    args = { headers: extra_headers.merge('content-type': 'application/xml; charset=utf-8') }
    args[:request] = { timeout: 60 }
    client = Faraday.new(**args) do |f|
      f.options.proxy = proxy_config if use_proxy?(url)
      f.adapter(:typhoeus, http_version: :httpv1_1)
    end
    client.basic_auth(*basic_auth.values) if basic_auth.present?

    response = raise_custom_exception(url) { client.post(url, body.to_s) }

    raise Non200Error.new("#{url} returned a non-200 response: #{response.status}", response.status) if raise_if_not_success && !response.success? # rubocop:disable Layout/LineLength
    response
  end

  def post_form_url_encoded(url, options = {})
    form = options.fetch(:form, {})
    auth_params = options.fetch(:auth_params, {})
    raise_if_not_success = options.fetch(:raise_if_not_success, false)

    args = { headers: { 'content-type' => 'application/x-www-form-urlencoded' } }
    client = Faraday.new(**args) do |f|
      f.options.proxy = proxy_config if use_proxy?(url)
      f.adapter(:typhoeus, http_version: :httpv1_1)
    end
    client.basic_auth(*auth_params[:basic_auth].values) if auth_params[:basic_auth].present?
    body = (form || {}).entries.map { |entry| entry.join('=') }.join('&')

    response = raise_custom_exception(url) { client.post(url, body) }
    raise Non200Error.new("#{url} returned a non-200 response: #{response}", response.status) if raise_if_not_success && !response.success? # rubocop:disable Layout/LineLength
    response
  end

  def post_json(url, options = {})
    verb_json(url, options.merge(verb: :post))
  end

  def put_json(url, options = {})
    verb_json(url, options.merge(verb: :put))
  end

  def verb_json(url, options = {})
    verb = options[:verb]&.downcase
    raise "Invalid HTTP verb: #{verb}" unless verb && %i[put post get].include?(verb.to_sym)
    params = options.fetch(:params, nil)
    headers = options.fetch(:headers, {})
    json_response = options.fetch(:json_response, true)
    bearer_token = options.fetch(:bearer_token, nil)
    timeout = options.fetch(:timeout, nil)
    raise_if_not_success = options.fetch(:raise_if_not_success, false)
    disable_proxy = options.fetch(:disable_proxy, false)
    basic_auth = options.fetch(:basic_auth, nil)
    raw_response = options.fetch(:raw_response, false)

    args = { headers: headers.merge('content-type' => 'application/json; charset=utf-8') }
    args[:request] = { timeout: timeout || 60 }
    client = Faraday.new(**args) do |f|
      f.options.proxy = proxy_config if use_proxy?(url) && !disable_proxy
      f.adapter(:typhoeus, http_version: :httpv1_1)
    end
    client.authorization('Bearer', bearer_token) if bearer_token.present?
    client.basic_auth(*basic_auth.values) if basic_auth.present?

    response = raise_custom_exception(url) { client.public_send(verb.to_sym, url, JSON.dump(params)) }
    return response if raw_response
    # TODO: We should always return the raw response and let the caller deal with it
    # Success and err cases will be different on different situations
    if response.success?
      res = response.body
      return res.present? && json_response ? JSON.parse(res) : res
    elsif raise_if_not_success
      raise Non200Error.new("#{url} returned a non-200 response: #{response.status}", response.status)
    end
    Log.info("Invalid #{verb.upcase} to #{url} on #{DateTime.now}: Status: #{response.status}, body: #{response.body}")
    response
  end

  def get_json(url, options = {})
    accept = options.fetch(:accept, nil)
    args = { headers: { 'content-type' => 'application/json; charset=utf-8' } }
    args[:headers] = args[:headers].merge('Accept'=> accept) if accept.present?
    args[:request] = { timeout: 60 }
    bearer_token = options.fetch(:bearer_token, nil)
    basic_auth = options.fetch(:basic_auth, nil)
    raw_response = options.fetch(:raw_response, false)
    client = Faraday.new(**args) do |f|
      f.options.proxy = proxy_config if use_proxy?(url)
      f.adapter(:typhoeus, http_version: :httpv1_1)
    end
    client.authorization('Bearer', bearer_token) if bearer_token.present?
    client.basic_auth(*basic_auth.values) if basic_auth.present?
    response = raise_custom_exception(url) { client.get(url) }
    raise Non200Error.new("#{url} returned a non-200 response: #{response.status}", response.status) unless response.success? # rubocop:disable Layout/LineLength
    res = response.body
    return res if raw_response
    res.present? ? JSON.parse(res) : res
  end

  def webhook_post(url, body, content_type, options = {})
    auth_params = options.fetch(:auth_params, {})
    raise_if_not_success = options.fetch(:raise_if_not_success, false)
    disable_proxy = options.fetch(:disable_proxy, false)
    raw_response = options.fetch(:raw_response, false)
    # protocol = auth_params.fetch(:protocol, BASIC)

    args = { headers: (auth_params[:headers] || {}).merge('content-type' => "application/#{content_type}; charset=utf-8") } # rubocop:disable Layout/LineLength
    args[:request] = { timeout: 60 }
    client = Faraday.new(**args) do |f|
      f.options.proxy = proxy_config if use_proxy?(url) && !disable_proxy
      f.adapter(:typhoeus, http_version: :httpv1_1)
    end
    case auth_params[:protocol]
    when BASIC
      client.basic_auth(*auth_params[:basic_auth].values) if auth_params[:basic_auth].present?
    when OAUTH
      client.authorization('Bearer', auth_params[:token]) if auth_params[:token].present?
    end

    body = body.to_s if content_type == 'xml'
    body = JSON.dump(body, mode: :compat) if content_type == 'json'
    response = raise_custom_exception(url) { client.post(url, body) }

    if response.success?
      return response if raw_response
      if response.headers['Content-Type']&.include?('application/json')
        res = response.body
        return res.present? ? JSON.parse(res) : res
      end
      return response # if content_type is xml, return response here
    elsif !response.success? && raise_if_not_success
      raise Non200Error.new("#{url} returned a non-200 response: #{response.status}", response.status)
    end
    Log.info("Invalid POST to #{url} on #{DateTime.now}: Status: #{response.status}, body: #{response.body}")
    response
  end

  def use_proxy?(url)
    return false if ENV['RACK_ENV']&.to_sym == :development && url.match?(/\/localhost:/)
    ENV['USE_OUTBOUND_PROXY']&.to_s == 'true' && proxy_url.present?
  end

  def http_client
    return Faraday unless proxy_url.present?
    Faraday.new(proxy: proxy_url)
  end

  def raise_custom_exception(url)
    yield
  rescue => e
    raise CustomFaradayError, "#{url}: #{e.message}"
  end

  # assumes username:password@url:port format in QUOTAGUARD_OUTBOUND_URL ENV variable
  def proxy_url
    ENV['OUTBOUND_PROXY_URL'] || ENV.fetch('QUOTAGUARD_OUTBOUND_URL', nil)
  end

  def proxy_config
    return @proxy_config if defined?(@proxy_config)
    uri = URI.parse(proxy_url)
    @proxy_config = {
      uri:      uri,
      user:     uri.user,
      password: uri.password
    }
  end

  def get_response_status(url)
    Faraday.new { |f| f.adapter(:typhoeus, http_version: :httpv1_1) }.get(url).status
  end
end
