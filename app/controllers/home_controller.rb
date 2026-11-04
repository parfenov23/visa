class HomeController < ApplicationController
  # Тариф для посетителей из Индии (по IP), если тариф и валюта не заданы в URL.
  INDIA_GEO_TARIFF = :custom_20

  def index
    @currency = params[:currency].present? ? params[:currency].to_sym : :eur
    @tariff = params[:tariff].present? ? params[:tariff].to_sym : :default
    apply_india_geo_pricing
    @currency = :usd if @tariff != :default

    @meta_price = case @tariff
                  when :custom_20 then "$15"
                  when :custom_50 then "$50"
                  when :custom_75 then "$75"
                  else "€9.99"
                  end
  end

  def success_invitation
    flash[:popup] = "submission_success"
    redirect_to root_path(tariff: params[:tariff].presence)
  end

  private

  # Посетитель с индийского IP на основной главной видит цены $15 / $20 / $30
  # (тариф custom_20, как на /in). Явный ?tariff= / ?currency= в URL важнее.
  # Выключить без деплоя кода: INDIA_GEO_PRICES=off.
  def apply_india_geo_pricing
    return if params[:tariff].present? || params[:currency].present?
    return unless india_geo_prices_enabled?
    return unless GeoCountry.india?(request.remote_ip)

    @tariff = INDIA_GEO_TARIFF
  end

  def india_geo_prices_enabled?
    ENV.fetch("INDIA_GEO_PRICES", "on").to_s.downcase != "off"
  end
end
