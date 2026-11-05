class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_locale

  # На домене russvisa.in весь сайт работает с индийскими ценами (тариф custom_20),
  # даже без ?tariff= в URL. Тот же список хостов — в config/routes.rb.
  INDIA_DOMAINS = %w[russvisa.in www.russvisa.in].freeze
  INDIA_TARIFF  = "custom_20"

  helper_method :india_domain?

  private

  def india_domain?
    INDIA_DOMAINS.include?(request.host)
  end

  def set_locale
    I18n.locale = 'en'
  end
end
