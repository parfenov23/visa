module ApplicationHelper
  def all_price_items(currency: :eur, tariff: :default)
    curr_currency = currency == :eur ? "€" : "$"
    current_tariff = Invitation.tariff_price(currency: currency, tariff: tariff)
    all_items = []
    package = :single
    all_items << {
      popular: true,
      title: "Most popular",
      description: "Single entry",
      last_desc: "Tourist invitation <br> (tourist confirmation and tourist voucher)",
      selector: {value: package, text: "Tourist single entry (up to 30 days) #{curr_currency} #{current_tariff.dig(package, :price)}"},
      price: current_tariff.dig(package, :price),
      currency: curr_currency,
      li: [
        "Ready in <b>30 minutes</b>",
        "For a visa up to <b>30 days</b>",
        "Invitation sent directly to <b>your email</b>"
      ]
    }
    package = :double
    all_items << {
      description: "Double entry",
      last_desc: "Tourist invitation <br> (tourist confirmation and tourist voucher)",
      selector: {value: package, text: "Tourist Double entry (up to 90 days) #{curr_currency} #{current_tariff.dig(package, :price)}"},
      price: current_tariff.dig(package, :price),
      currency: curr_currency,
      li: [
        "Ready in <b>30 minutes</b>",
        "For a visa up to <b>90 days</b>",
        "Invitation sent directly to <b>your email</b>"
      ]
    } if current_tariff.dig(package, :price).present?

    package = :multi
    all_items << {
      description: "Multiple entry",
      last_desc: "Tourist invitation <br> (tourist confirmation and tourist voucher)",
      selector: {value: package, text: "Tourist Multiple entry (up to 180 days) #{curr_currency} #{current_tariff.dig(package, :price)}"},
      price: current_tariff.dig(package, :price),
      currency: curr_currency,
      li: [
        "Ready in <b>30 minutes</b>",
        "For a visa up to <b>180 days</b>",
        "Invitation sent directly to <b>your email</b>"
      ]
    } if current_tariff.dig(package, :price).present?

    package = :multi_usa
    all_items << {
      hide: true,
      selector: {
        value: package,
        text: "Tourist Multiple entry (3 years) #{curr_currency} #{current_tariff.dig(package, :price)} - US citizens only"
      },
      price: current_tariff.dig(package, :price),
      currency: curr_currency,
    } if current_tariff.dig(package, :price).present?

    all_items
  end

  def default_price(currency: :eur, tariff: :default)
    curr_currency = currency == :eur ? "€" : "$"
    current_tariff = Invitation.tariff_price(currency: currency, tariff: tariff)
    curr_price = current_tariff.dig(:single, :price)
    "#{curr_currency} #{curr_price}"
  end

  def all_country

  end

  def get_name_package(package)
    { single: "Однократная", double: "Двукратная", multi: "Многократная", multi_usa: "Многократная" }[package]
  end
end
