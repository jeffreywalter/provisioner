require 'net/http'
require 'json'

class BaseHTTP
  def self.post(endpoint, body, headers={})
    uri = URI.parse(endpoint)
    req = Net::HTTP::Post.new(uri.request_uri)
    set_headers(req, headers)
    req.body = body.to_json
    # puts("Post: #{uri}\n   Headers: #{headers}\n   Body: #{body}")
    http_request(uri, req)
  end

  def self.get(endpoint, headers={})
    uri = URI.parse(endpoint)
    req = Net::HTTP::Get.new(uri.request_uri)
    set_headers(req, headers)
    # puts("Get: #{uri}\n   Headers: #{headers}")
    http_request(uri, req)
  end

  def self.post_jwt(endpoint, body, headers={})
    uri = URI.parse(endpoint)
    req = Net::HTTP::Post.new(uri.request_uri)
    set_headers(req, headers)
    req.form_data = body
    # puts("Post: #{uri}\n   Headers: #{headers}\n   Body: #{body}")
    http_request(uri, req)
  end

  private

  def self.http_request(uri, req)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    response = http.request(req)
    JSON.parse(body_for(response))
  end

  def self.body_for(response)
    response.body || "{}"
  end

  def self.set_headers(req, headers)
    headers.each do |k,v|
      req.add_field(k.to_s, v.to_s)
    end
  end
end
