class Invitation < ApplicationRecord
  before_create :set_price, :set_accomodation, :set_meals

  ALL_ACCOMODATION = ["Double (DBL)", "Twin (TWN)", "Single (SGL)"]
  ALL_MEALS = %w[BB RO HB FB AI UAI CB]

  def self.tariff_price(currency: :eur, tariff: :default)
    all_tariffs = {
      eur: {
        default: {
          single: { price: 9.99 },
          single_90: { price: 14.99 },
          double: { price: 14.99 },
          multi: { price: 24.99 },
          multi_usa: {price: 44.99}
        }
      },
      usd: {
        default: {
          single: {price: 12},
          single_90: { price: 17 },
          double: {price: 17},
          multi: {price: 30},
          multi_usa: {price: 49.99}
        },
        sale_10: {
          single: { price: 10 },
          single_90: { price: 10 },
          double: { price: 10 },
          multi: { price: 10 }
        },
        sale_20: {
          single: { price: 20 },
          double: { price: 20 },
          multi: { price: 20 }
        },
        custom_20: {
          single: { price: 15 },
          single_90: { price: 20 },
          double: { price: 20 },
          multi: { price: 30 }
        },
        custom_50: {
          single: { price: 35 },
          single_90: { price: 50 },
          double: { price: 50 }
        },
        custom_75: {
          single: { price: 50 },
          single_90: { price: 75 },
          double: { price: 75 }
        }
      }
    }

    all_tariffs[currency][tariff]
  end

  # Какие поля можно использовать в фильтрах ActiveAdmin (Ransack)
  def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      invitation_type_id
      surname
      name
      middlename
      sex
      citizenship
      birthDate
      arival_date
      departure_date
      passport
      visa_obtain_place
      cities
      hotels
      offname
      email
      website
      promocode
      comments
      created_at
      updated_at
    ]
  end

  # (Если есть ассоциации — можно добавить сюда)
  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.all_accomodation
    []
  end

  def current_id
    created_at.strftime("%d%m%y%H%M")
  end

  def citizenship_title(lang: :en)
    country = Country.all.find{|country| country[:code] == self.citizenship} || {}
    lang == :ru ? country[:title_ru] : country[:title]
  end

  def send_notify_email
    begin
      InvitationMailer.new_order(self).deliver_now
      InvitationMailer.new_order(self, true).deliver_now
    rescue
    end
  end

  private

  def set_price
    get_tariff_price = Invitation.tariff_price(currency: self.currency.to_sym, tariff: self.tariff.to_sym)
    self.price = get_tariff_price.dig(self.package.to_sym, :price)
  end

  def set_accomodation
    self.accomodation = ALL_ACCOMODATION.first
  end

  def set_meals
    self.meals = ALL_MEALS.first
  end
end
