module HttpHelper
  def self.included(base)
    base.extend(HttpHelperMethods)
    base.include(HttpHelperMethods)
  end

  module HttpHelperMethods
    def post_json(url, options = {})
      params = options.fetch(:params, nil)
      json_response = options.fetch(:json_response, true)
      header = options.fetch(:header, {})

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      full_url = uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
      header = { 'Content-Type' => 'application/json' }.merge(header)
      req = Net::HTTP::Post.new(full_url, header)
      req.body = params.is_a?(Hash) ? params.to_json : params
      res = http.request(req)&.body
      res.present? && json_response ? JSON.parse(res) : res
    end

    def post_form(url, options = {})
      params = options.fetch(:params, nil)
      json_response = options.fetch(:json_response, true)

      res = Net::HTTP.post_form(URI.parse(url), params)&.body
      res.present? && json_response ? JSON.parse(res) : res
    end

    def post_text(url, body)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      full_url = uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
      header = { 'Content-Type' => 'text/plain' }
      req = Net::HTTP::Post.new(full_url, header)
      req.body = body
      http.request(req)&.body
    end

    # to do: should combine post_json and get_json or take common function out
    def get_json(url, options = {})
      json_response = options.fetch(:json_response, true)
      header = options.fetch(:header, { 'Content-Type' => 'application/json' })

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      full_url = uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
      req = Net::HTTP::Get.new(full_url, header)
      res = http.request(req)&.body
      res.present? && json_response ? JSON.parse(res) : res
    end

    def get_pdf(url, options = {})
      header = options.fetch(:header, { 'Content-Type' => 'application/pdf' })

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      full_url = uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
      req = Net::HTTP::Get.new(full_url, header)
      http.request(req)&.body
    end

    def get_response_status(url)
      HTTP.get(url).status
    end
  end
end
