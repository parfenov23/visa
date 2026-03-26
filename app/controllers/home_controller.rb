class HomeController < ApplicationController
  def index
    @currency = params[:currency].present? ? params[:currency].to_sym : :eur
    @tariff = params[:tariff].present? ? params[:tariff].to_sym : :default
    @currency = :usd if @tariff != :default

    @meta_price = case @tariff
                  when :custom_20 then "$20"
                  when :custom_50 then "$50"
                  when :custom_75 then "$75"
                  else "€9.99"
                  end
  end
end
