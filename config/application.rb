require 'logger'
require_relative 'boot'

require 'rails/all'
Bundler.require(*Rails.groups)

module Visatoruss
  class Application < Rails::Application
#=======================================================================================================================
    #TIMEZONE
    config.time_zone = ActiveSupport::TimeZone[3].name
#=======================================================================================================================
    #MAIL
    config.action_mailer.delivery_method = :smtp
    # config.action_mailer.smtp_settings = {
    #   address:              Rails.application.credentials.smtp[:address],
    #   port:                 Rails.application.credentials.smtp[:port],
    #   domain:               Rails.application.credentials.smtp[:domain],
    #   user_name:            Rails.application.credentials.smtp[:user_name],
    #   password:             Rails.application.credentials.smtp[:password],
    #   authentication:       Rails.application.credentials.smtp[:authentication],
    #   ssl:                  Rails.application.credentials.smtp[:ssl],
    #   enable_starttls_auto: Rails.application.credentials.smtp[:enable_starttls_auto]
    # }
    config.action_mailer.show_previews = true
#=======================================================================================================================
    #SESSION AND COOKIES
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore
    config.session_store :cookie_store
    config.force_ssl = false if Rails.env.production?
#=======================================================================================================================
    #CORS
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :options, :delete, :patch]
      end
    end
#=======================================================================================================================
#LOGS
#     if Rails.env.production? || Rails.env.staging?
#       config.logger = Logger.new(STDOUT)
#       config.log_level = :ERROR
#     end
#=======================================================================================================================
#OTHER
    # config.active_job.queue_adapter = :sidekiq
    config.action_view.field_error_proc = Proc.new { |html_tag, instance| "#{html_tag}".html_safe }
    Rails.autoloaders.main.ignore('app/admin', 'app/views')
    config.active_record.legacy_connection_handling = false
    config.exceptions_app = self.routes
    config.sass.preferred_syntax = :scss

    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')
  end
end
