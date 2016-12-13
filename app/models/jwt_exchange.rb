class JWTExchange
  attr_reader :client_secret, :api_key, :org, :technical_acct, :ims_host, :expiry_time

  def initialize(opts)
    @client_secret = opts[:client_secret]
    @api_key = opts[:api_key]
    @ims_host = opts[:ims_host]
    @expiry_time = opts[:expiry_time]
    @org = opts[:org]
    @technical_acct = opts[:user]

    @private_key = opts[:private_key]
  end

  def exchange_jwt
    url = "https://#{ims_host}/ims/exchange/jwt"
    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Cache-Control' => 'no-cache'
    }

    ::BaseHTTP.post_jwt url, body, headers
  end

  def body
    {
      client_id: api_key,
      client_secret: client_secret,
      jwt_token: jwt_token
    }
  end

  def jwt_token
    @jwt_token ||= JWT.encode jwt_payload, rsa_private, 'RS256'
  end

  def rsa_private
    @rsa_private ||= OpenSSL::PKey::RSA.new(@private_key)
  end

  def jwt_payload
    {
      exp: expiry_time,
      iss: org,
      sub: technical_acct,
      jti: '1479490921',
      iat: expiry_time - 10000,
      aud: "https://#{ims_host}/c/#{api_key}",
      "https://#{ims_host}/s/ent_user_sdk" => true
    }
  end
end
