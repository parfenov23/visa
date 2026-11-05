class Invitation < ApplicationRecord
  # Виртуальное поле для выбора гостиницы из базы в админ-форме (не сохраняется).
  attr_accessor :hotel_picker

  before_create :set_price, :set_accomodation, :set_meals, :assign_seals, :assign_verify_token,
                :assign_invitation_number
  before_save :normalize_dates, :normalize_offers, :stamp_done_at

  # Строковые поля дат, заполняемые пользователем на форме заказа.
  DATE_FIELDS = %w[birthDate arival_date departure_date].freeze

  ALL_ACCOMODATION = ["Double (DBL)", "Twin (TWN)", "Single (SGL)"]
  ALL_MEALS = %w[RO BB HB FB AI UAI CB]

  # Ключ pg_advisory_xact_lock для выдачи номеров приглашений.
  INVITATION_NUMBER_LOCK = 2310261250

  # Number of seal variants available in public/signs (1.png .. 6.png).
  SEALS_COUNT = 6
  # Default fixed-order pairs used when SEALS_MODE=fixed and SEALS_FIXED_PAIRS is unset.
  DEFAULT_FIXED_SEAL_PAIRS = "1-2,3-4,5-6".freeze

  # Two seals in one invitation must be different and within the available range.
  validates :seal_left, :seal_right,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: SEALS_COUNT },
            allow_nil: true
  validate :seals_must_differ

  # 'random' (default) — pick 2 distinct seals; 'fixed' — cycle predefined pairs.
  def self.seals_mode
    (ENV['SEALS_MODE'].presence || 'random').to_s.downcase
  end

  # Parsed fixed pairs, e.g. [[1,2],[3,4],[5,6]].
  def self.fixed_seal_pairs
    raw = ENV['SEALS_FIXED_PAIRS'].presence || DEFAULT_FIXED_SEAL_PAIRS
    pairs = raw.split(',').map { |p| p.split('-').map { |n| n.strip.to_i } }
    pairs.select { |pair| pair.size == 2 && pair.all? { |n| n.between?(1, SEALS_COUNT) } && pair.uniq.size == 2 }
  end

  # Returns [left, right] for the next invitation according to the configured mode.
  def self.next_seal_pair
    if seals_mode == 'fixed'
      pairs = fixed_seal_pairs
      pairs = [[1, 2]] if pairs.empty?
      pairs[count % pairs.size]
    else
      (1..SEALS_COUNT).to_a.sample(2)
    end
  end

  PURPOSES = {
    'tourism'        => 'Tourism',
    'auto_tourism'   => 'Auto tourism',
    'target_tourism' => 'Target tourism'
  }.freeze

  PURPOSES_RU = {
    'tourism'        => 'Туризм',
    'auto_tourism'   => 'Автотуризм',
    'target_tourism' => 'Целевой туризм'
  }.freeze

  STATUSES = {
    'in_progress' => 'In progress',
    'done'        => 'Done',
    'correction'  => 'Correction',
    'duplicate'   => 'Duplicate (повторная)',
    'cancelled'   => 'Cancelled (отказ)'
  }.freeze

  # Цвета статусов в списке заявок админки (in_progress — синий по умолчанию).
  STATUS_COLORS = {
    'done'       => '#1f9d55',
    'correction' => '#d97706',
    'duplicate'  => '#6b7280',
    'cancelled'  => '#dc2626'
  }.freeze

  # Аннулированные заявки не удаляются, но не учитываются в статистике и рассылках.
  VOID_STATUSES = %w[duplicate cancelled].freeze

  validates :status, inclusion: { in: STATUSES.keys }

  scope :active,       -> { where.not(status: VOID_STATUSES) }
  scope :void,         -> { where(status: VOID_STATUSES) }
  scope :not_agency,   -> { where(agency: false) }

  # --- Письмо с предложениями (галочки в заявке) ----------------------------
  # Порядок = порядок блоков в письме. enabled: false — галочка скрыта, пока
  # нет текста и страницы. Новое предложение: запись здесь + partial
  # app/views/offers_mailer/_<key>.html.erb.
  OFFERS = {
    'insurance'         => { label: 'Страховка',                          path: '/insurance',        enabled: true },
    'vip'               => { label: 'VIP-встреча в Москве ($220)',        path: '/airport-transfer', enabled: true },
    'train'             => { label: 'ЖД билеты',                          path: '/train-tickets',    enabled: true },
    'hotel'             => { label: 'Бронирование гостиницы',             path: nil,                 enabled: false },
    'sim'               => { label: 'Российская SIM / eSIM',              path: nil,                 enabled: false },
    'registration'      => { label: 'Регистрация по месту пребывания',    path: nil,                 enabled: false },
    'invitation_change' => { label: 'Продление / изменение приглашения', path: nil,                 enabled: false }
  }.freeze

  # Через сколько после Done уходит письмо с предложениями.
  OFFERS_DELAY = 5.minutes

  def self.enabled_offers
    OFFERS.select { |_, o| o[:enabled] }
  end

  # Заявки, которым пора отправить письмо с предложениями.
  scope :offers_due, lambda {
    where(status: 'done', agency: false, offers_sent_at: nil)
      .where.not(email: [nil, ''])
      .where('done_at <= ?', OFFERS_DELAY.ago)
      .where("jsonb_array_length(offers) > 0")
  }

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

  # 10-значный номер приглашения: ddmmyyHHMM момента создания (UTC+3).
  # Если номер уже занят (несколько заявок за одну минуту), берётся следующий
  # свободный: 2310261250 -> 2310261251. Уникальность гарантирует индекс в БД.
  validates :invitation_number, uniqueness: true, allow_nil: true

  def self.next_number(number)
    (number.to_i + 1).to_s.rjust(10, "0")
  end

  # Граждане Индии и Непала платят по индийскому тарифу (как на /in), даже если
  # заявку подали с основной главной. Коды в БД трёхбуквенные; двухбуквенные — на всякий случай.
  INDIA_CITIZENSHIPS = %w[IND NPL IN NP].freeze
  INDIA_TARIFF = :custom_20

  def self.india_citizen?(code)
    INDIA_CITIZENSHIPS.include?(code.to_s.strip.upcase)
  end

  # Цена пакета по индийскому тарифу или nil, если пакета в нём нет (multi_usa).
  def self.india_price(package)
    tariff_price(currency: :usd, tariff: INDIA_TARIFF).dig(package.to_s.to_sym, :price)
  end

  DEFAULT_CURRENCY = "eur"
  DEFAULT_TARIFF = "default"

  def self.currencies
    tariff_price_table.keys.map(&:to_s)
  end

  def self.tariffs
    tariff_price_table.values.flat_map(&:keys).uniq.map(&:to_s)
  end

  # Пакеты тарифа; если валюта/тариф не заданы или такой пары нет — все пакеты.
  def self.packages_for(currency:, tariff:)
    prices = tariff_price(currency: (currency.presence || DEFAULT_CURRENCY).to_sym,
                          tariff: (tariff.presence || DEFAULT_TARIFF).to_sym)
    keys = prices ? prices.keys : tariff_price_table.values.flat_map(&:values).flat_map(&:keys).uniq
    keys.map(&:to_s)
  end

  def self.tariff_price(currency: :eur, tariff: :default)
    tariff_price_table.dig(currency.to_s.to_sym, tariff.to_s.to_sym)
  end

  def self.tariff_price_table
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

    all_tariffs
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
      invitation_number
      agency
      seal_high
      print_seal
      cancel_reason
    ]
  end

  # (Если есть ассоциации — можно добавить сюда)
  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.all_accomodation
    []
  end

  # Приводит введённую пользователем дату к "dd.mm.yyyy". Если JS-датапикер на
  # форме не сработал, дата приходит в свободном формате: "20/08/2026",
  # "04 12 1987", "20-08-2026", "2026-08-20" и т.п. Понимает разделители
  # ". / - пробел" и порядок dd.mm.yyyy или yyyy-mm-dd.
  # Возвращает nil, если строка не распознана как дата.
  def self.normalize_date_string(value)
    parts = value.to_s.strip.split(%r{[./\-\s]+})
    return nil unless parts.size == 3 && parts.all? { |p| p.match?(/\A\d+\z/) }

    day, month, year = parts
    day, year = year, day if day.length == 4
    return nil unless year.length == 4

    date = Date.new(year.to_i, month.to_i, day.to_i) rescue nil
    date&.strftime("%d.%m.%Y")
  end

  def current_id
    invitation_number || created_at.strftime("%d%m%y%H%M")
  end

  def citizenship_title(lang: :en)
    country = Country.find_by_code(self.citizenship)
    return nil unless country
    lang == :ru ? country.title_ru : country.title
  end

  # Полное имя туриста для отображения (на странице верификации и т.п.).
  def full_name
    [surname, name, middlename].map { |p| p.to_s.strip }.reject(&:empty?).join(" ")
  end

  def send_notify_email
    begin
      InvitationMailer.new_order(self).deliver_now
      InvitationMailer.new_order(self, true).deliver_now
    rescue
    end
  end

  # Отмеченные, но ещё не отправленные предложения (в порядке OFFERS).
  def pending_offers
    (Array(offers) - Array(offers_sent)) & self.class.enabled_offers.keys
  end

  # Отправляет письмо с ещё не отправленными предложениями.
  # Возвращает список отправленных ключей ([] — отправлять нечего).
  def deliver_offers!
    with_lock do
      keys = email.present? ? pending_offers : []
      if keys.any?
        OffersMailer.offers(self, keys).deliver_now
        update_columns(offers_sent: (Array(offers_sent) | keys), offers_sent_at: Time.current, updated_at: Time.current)
      end
      keys
    end
  end

  # Дата приезда как Date (arival_date хранится строкой dd.mm.yyyy); nil, если не распознана.
  def arrival_on
    Date.strptime(arival_date.to_s, '%d.%m.%Y')
  rescue ArgumentError
    nil
  end

  def void?
    VOID_STATUSES.include?(status)
  end

  def get_purposes
    PURPOSES_RU[purpose]
  end

  private

  # Из админки галочки приходят массивом строк с пустым элементом.
  def normalize_offers
    self.offers = Array(offers).map(&:to_s).reject(&:blank?).uniq & OFFERS.keys
    self.offers_sent = Array(offers_sent).map(&:to_s).uniq
  end

  # Момент первого перевода в Done: от него отсчитываются 5 минут до письма.
  def stamp_done_at
    self.done_at ||= Time.current if status == 'done'
  end

  # Не распознанные значения оставляем как есть, чтобы не терять данные.
  def normalize_dates
    DATE_FIELDS.each do |field|
      normalized = self.class.normalize_date_string(self[field])
      self[field] = normalized if normalized
    end
  end

  def assign_seals
    return if seal_left.present? && seal_right.present?
    self.seal_left, self.seal_right = self.class.next_seal_pair
  end

  # Короткий уникальный токен для публичной ссылки верификации (в QR).
  def assign_verify_token
    return if verify_token.present?
    self.verify_token = loop do
      token = SecureRandom.alphanumeric(10)
      break token unless self.class.exists?(verify_token: token)
    end
  end

  # Advisory-lock держится до конца транзакции create, поэтому параллельные
  # заявки выбирают номер по очереди и не получают одинаковый.
  def assign_invitation_number
    return if invitation_number.present?
    self.class.connection.execute("SELECT pg_advisory_xact_lock(#{INVITATION_NUMBER_LOCK})")
    number = (created_at || Time.current).strftime("%d%m%y%H%M")
    number = self.class.next_number(number) while self.class.exists?(invitation_number: number)
    self.invitation_number = number
  end

  def seals_must_differ
    return if seal_left.blank? || seal_right.blank?
    errors.add(:seal_right, "must differ from the left seal") if seal_left == seal_right
  end

  # Цену, введённую вручную в админке, не перезаписываем.
  def set_price
    self.currency = DEFAULT_CURRENCY if currency.blank?
    self.tariff = DEFAULT_TARIFF if tariff.blank?
    apply_india_citizen_tariff if price.blank?
    return if price.present?

    self.price = Invitation.tariff_price(currency: currency, tariff: tariff)&.dig(package.to_s.to_sym, :price)
  end

  # Только для базового тарифа: акционные и агентские тарифы не трогаем.
  def apply_india_citizen_tariff
    return unless self.class.india_citizen?(citizenship)
    return unless tariff.blank? || tariff.to_s == "default"
    return if self.class.india_price(package).blank?

    self.tariff = INDIA_TARIFF.to_s
    self.currency = "usd"
  end

  def set_accomodation
    self.accomodation = ALL_ACCOMODATION.first
  end

  def set_meals
    self.meals = ALL_MEALS.first
  end
end
