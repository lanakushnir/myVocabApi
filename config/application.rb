require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MyVocabApi
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.action_dispatch.default_headers = {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Request-Method' => %w{GET POST PUT OPTIONS}.join(","),
      # 'Access-Control-Request-Method' => '*',
      'Access-Control-Allow-Headers' => %w{Origin X-Requested-With Content-Type Accept Authorization}.join(",")
    }

    # added from https://docs.mongodb.com/ruby-driver/master/tutorials/6.1.0/mongoid-rails/#using-mongoid-with-a-new-rails-application
    # config.mongoid.logger = Logger.new($stdout, :warn)
  end
end
