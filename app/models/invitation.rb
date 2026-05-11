class Invitation < ApplicationRecord
  before_create :set_price, :set_accomodation, :set_meals

  ALL_ACCOMODATION = ["Double (DBL)", "Twin (TWN)", "Single (SGL)"]
  ALL_MEALS = %w[BB RO HB FB AI UAI CB]

  PURPOSES = {
    'tourism'        => 'Tourism',
    'auto_tourism'   => 'Auto tourism',
    'target_tourism' => 'Target tourism'
  }.freeze

  STATUSES = {
    'in_progress' => 'In progress',
    'done'        => 'Done',
    'correction'  => 'Correction'
  }.freeze

  scope :created_in_period, ->(period) {
    now = Time.zone.now
    range =
      case period.to_s
      when 'today'      then now.beginning_of_day..now.end_of_day
      when 'yesterday'  then 1.day.ago.beginning_of_day..1.day.ago.end_of_day
      when 'this_week'  then now.beginning_of_week..now.end_of_week
      when 'last_week'  then 1.week.ago.beginning_of_week..1.week.ago.end_of_week
      when 'this_month' then now.beginning_of_month..now.end_of_month
      when 'last_month' then 1.month.ago.beginning_of_month..1.month.ago.end_of_month
      end
    range ? where(created_at: range) : all
  }

  def self.ransackable_scopes(_auth_object = nil)
    [:created_in_period]
  end

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
      additional_info
      purpose
      status
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
    country = Country.find_by_code(self.citizenship)
    return nil unless country
    lang == :ru ? country.title_ru : country.title
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
