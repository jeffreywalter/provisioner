require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Provisioner
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    config.autoload = :classic
    # -- all .rb files in that directory are automatically loaded.
    config.assets.precompile += %w(duplicate.js clone.js copy_down.js)
    config.before_configuration do
      io_env = ENV['IO_ENV'] || 'qa'
      dev = File.join(Rails.root, 'config', "io-#{io_env}.yml")
      YAML.load(ERB.new(File.read(dev)).result).each do |key, value|
        ENV[key.to_s] = value.to_s unless ENV.key?(key.to_s)
      end if File.exists?(dev)
    end
  end
end
