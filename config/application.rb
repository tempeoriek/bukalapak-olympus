require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

# Custom .env* loader
ignore_dotenv = ENV['IGNORE_DOTENV']
if ignore_dotenv.nil? || ignore_dotenv.empty? || ignore_dotenv == '0'
  require 'dotenv/rails'
end

module Olympus
  class Application < Rails::Application
    config.api_only = true
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.enable_dependency_loading = true
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Jakarta'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.yml').to_s]
    config.i18n.default_locale = :id
    config.i18n.fallbacks = [:en]

    I18n.enforce_available_locales = false
    config.i18n.available_locales = ['id']
    I18n.locale = 'id'

    # logging configuration
    config.log_level = :unknown # changed to :unknown to avoid logging access_token, payload, and other stuffs
    config.colorize_logging = true

    config.logstash.type = :stdout
    config.logstash.formatter = :json_lines

    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Logstash.new
    config.lograge.custom_options = lambda do |event|
      exceptions = %w(controller action format)
      {
        params: event.payload[:params].except(*exceptions),
      }.merge(event.payload.slice(:ip, :uuid, :current_user, :agent, :session_id))
    end
  end
end
