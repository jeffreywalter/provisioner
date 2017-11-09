class AccessToken
  attr_reader :client_secret, :org, :scope, :technical_acct, :api_key, :ims_host, :private_key

  def initialize(options={})
    @client_secret = ENV['IO_CLIENT_SECRET']
    @api_key = ENV['IO_API_KEY']
    @ims_host = ENV['IO_IMS_HOST']
    @private_key = ENV['IO_PRIVATE_KEY']
    @org = ENV['IO_ORG_ID']
    @scope = ENV['IO_SCOPE']
    @technical_acct = ENV['IO_TECHNICAL_ACCT']
  end

  def generate
    @access_token ||= fetch_access_token
  end

  private

  def fetch_access_token
    return ENV['IO_ACCESS_TOKEN'] if ENV['IO_ENV'] == 'dev'
    opts = {
      client_secret: client_secret,
      api_key: api_key,
      ims_host: ims_host,
      private_key: private_key,
      org: org,
      scope: scope,
      user: technical_acct,
      expiry_time: Time.now.to_i + (60 * 60 * 24)
    }
    response = JWTExchange.new(opts).exchange_jwt
    puts response

    response['access_token']
  rescue Exception => e
    puts "There was an error with your request: #{e.message}"
    raise e
  end
end
