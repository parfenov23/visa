class HomeController < ApplicationController
  def index
    @currency = params[:currency].present? ? params[:currency].to_sym : :eur
    @tariff = params[:tariff].present? ? params[:tariff].to_sym : :default
    @currency = :usd if @tariff != :default
  end
end
