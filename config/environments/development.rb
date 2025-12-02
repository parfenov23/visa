Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = false

  # Enable/disable caching. By default caching is disabled.
  # To toggle cache run command: rails dev:cache
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.static_cache_control = "public, max-age=172800"
    config.cache_store = :redis_store, "redis://127.0.0.1:6379/0/cache", { expires_in: 1200.minutes }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.hosts << /.*\.ngrok-free\.app/

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Don't care if the mailer can't send.
  config.action_mailer.delivery_method = :smtp

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.action_mailer.default_url_options = { host: '127.0.0.1:3000' }
  config.action_controller.default_url_options = { host: 'localhost', port: 3000 }

  # config.after_initialize do
  #   ActiveRecord::Base.logger       = Rails.logger.clone
  #   ActiveRecord::Base.logger.level = Logger::WARN
  # end
  config.active_storage.service = :local

  # config.lograge.enabled = true
  # config.lograge.formatter = Lograge::Formatters::Json.new

  config.action_mailer.smtp_settings = {
    address:              "smtp.yandex.ru",
    port:                 465,
    domain:               $SITE_HOST,
    user_name:            ENV["SMTP_USERNAME"],   # полный адрес почты
    password:             ENV["SMTP_PASSWORD"],
    authentication:       "login",
    ssl:                  true
  }
end
