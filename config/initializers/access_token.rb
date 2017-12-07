require 'ruby_adobe_io'

AdobeIo.configure do |config|
  config.client_secret = ENV['IO_CLIENT_SECRET']
  config.api_key = ENV['IO_API_KEY']
  config.ims_host = ENV['IO_IMS_HOST']
  config.private_key = ENV['IO_PRIVATE_KEY']
  config.iss = ENV['IO_ISS']
  config.sub = ENV['IO_SUB']
  config.scope = ENV['IO_SCOPE']
  config.logger.level = ARGV.include?('-v') ? Logger::DEBUG : Logger::INFO
end
