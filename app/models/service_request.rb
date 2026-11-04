# Заявка на доп. услугу: страховка, ЖД билеты или VIP-встреча в аэропорту.
#
# Общие поля — колонками (ФИО, email, гражданство, паспорт, даты, цена),
# поля конкретной услуги — в jsonb `details` (через store_accessor),
# чек-лист менеджера для VIP-встречи — в jsonb `checklist`.
class ServiceRequest < ApplicationRecord
  KINDS = {
    'insurance' => 'Страховка',
    'train'     => 'ЖД билеты',
    'vip'       => 'VIP-встреча в аэропорту'
  }.freeze

  STATUSES = {
    'new'         => 'Новая',
    'in_progress' => 'В работе',
    'done'        => 'Выполнена',
    'cancelled'   => 'Отменена'
  }.freeze

  STATUS_COLORS = {
    'new'         => '#2563eb',
    'in_progress' => '#d97706',
    'done'        => '#1f9d55',
    'cancelled'   => '#6b7280'
  }.freeze

  # --- Страховка ---------------------------------------------------------
  # Ставка в сутки (USD) по гражданству; для остальных стран — DEFAULT.
  INSURANCE_RATES = { 'IN' => 1.35, 'NP' => 1.35 }.freeze
  INSURANCE_DEFAULT_RATE = 2.0
  INSURANCE_MAX_DAYS = 180
  INSURANCE_SUM_INSURED = 30_000

  # --- ЖД билеты -----------------------------------------------------------
  SEAT_CLASSES = {
    'seated' => 'Seated',
    'coupe'  => 'Compartment (4-berth)',
    'sv'     => 'First class SV (2-berth)'
  }.freeze

  DEPARTURE_TIMES = {
    'morning' => 'Morning (06:00–12:00)',
    'day'     => 'Afternoon (12:00–18:00)',
    'evening' => 'Evening (18:00–24:00)',
    'night'   => 'Night (00:00–06:00)',
    'any'     => 'Any time'
  }.freeze

  MAX_PASSENGERS = 10

  # --- VIP-встреча -------------------------------------------------------
  VIP_PRICE = 220
  VIP_CHECKLIST = {
    'docs_checked'     => 'Документы проверены (приглашение = виза)',
    'fsb_letter_ready' => 'Письмо для погранслужбы ФСБ подготовлено',
    'greeter_assigned' => 'Встречающий назначен',
    'manager_assigned' => 'Дежурный менеджер назначен'
  }.freeze

  # --- Файлы ---------------------------------------------------------------
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/heic image/heif application/pdf].freeze
  MAX_FILE_SIZE = 10.megabytes

  belongs_to :invitation, optional: true

  has_one_attached :passport_copy
  has_one_attached :visa_copy

  store_accessor :details,
                 :from_city, :to_city, :departure_time, :seat_class, :passengers, # ЖД
                 :arrival_time, :flight_number, :hotel_address, :invitation_ref   # VIP

  store_accessor :checklist, *VIP_CHECKLIST.keys

  # Чек-лист приходит из админки строками "0"/"1" — читаем как boolean.
  VIP_CHECKLIST.each_key do |key|
    define_method(key) { ActiveModel::Type::Boolean.new.cast(super()) || false }
    define_method("#{key}?") { public_send(key) }
  end

  before_validation :normalize_fields
  before_validation :assign_price, on: :create

  validates :kind,   inclusion: { in: KINDS.keys }
  validates :status, inclusion: { in: STATUSES.keys }
  validates :email,  presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate  :attachments_are_valid

  with_options if: :insurance? do
    validates :citizenship, :date_from, :date_to, presence: true
    validate :insurance_period_is_valid
    validate :insurance_person_given
  end

  with_options if: :train? do
    validates :from_city, :to_city, :date_from, :seat_class, presence: true
    validates :seat_class, inclusion: { in: SEAT_CLASSES.keys }, allow_blank: true
    validates :departure_time, inclusion: { in: DEPARTURE_TIMES.keys }, allow_blank: true
    validate :passengers_in_range
    validate :passport_copy_attached
  end

  with_options if: :vip? do
    validates :full_name, :date_from, :arrival_time, :flight_number, :hotel_address, presence: true
    validate :passengers_in_range
    validate :passport_copy_attached
  end

  validate :trip_date_not_in_past, on: :create

  scope :recent, -> { order(created_at: :desc) }

  KINDS.each_key do |k|
    define_method("#{k}?") { kind == k }
  end

  def self.insurance_rate(citizenship)
    INSURANCE_RATES.fetch(citizenship.to_s.strip.upcase, INSURANCE_DEFAULT_RATE)
  end

  # Количество суток страховки: обе даты включительно.
  def insurance_days
    return nil if date_from.blank? || date_to.blank?

    (date_to - date_from).to_i + 1
  end

  def kind_title
    KINDS[kind] || kind
  end

  def status_title
    STATUSES[status] || status
  end

  def citizenship_title
    return nil if citizenship.blank?

    Country.find_by_code(citizenship)&.title || citizenship
  end

  def seat_class_title
    SEAT_CLASSES[seat_class] || seat_class
  end

  def departure_time_title
    DEPARTURE_TIMES[departure_time] || departure_time
  end

  def price_label
    return nil if price.blank?

    "#{format('%.2f', price).sub(/\.00\z/, '')} #{currency.to_s.upcase}"
  end

  # Текстовые строки заявки для писем и админки: [[подпись, значение], ...].
  def summary_lines
    lines = [['Service', kind_title_en]]
    lines << ['Full name', full_name] if full_name.present?
    lines << ['Citizenship', citizenship_title] if citizenship.present?
    lines << ['Passport number', passport_number] if passport_number.present?

    case kind
    when 'insurance'
      lines << ['Insurance period', "#{fmt(date_from)} — #{fmt(date_to)} (#{insurance_days} days)"]
      lines << ['Daily rate', "USD #{self.class.insurance_rate(citizenship)}"]
    when 'train'
      lines << ['Route', "#{from_city} → #{to_city}"]
      lines << ['Travel date', fmt(date_from)]
      lines << ['Preferred departure', departure_time_title] if departure_time.present?
      lines << ['Class', seat_class_title]
      lines << ['Passengers', passengers]
    when 'vip'
      lines << ['Arrival', "#{fmt(date_from)} #{arrival_time}"]
      lines << ['Flight', flight_number]
      lines << ['Hotel / address in Moscow', hotel_address]
      lines << ['Passengers', passengers]
      lines << ['Invitation number', invitation_ref] if invitation_ref.present?
    end

    lines << ['Phone / WhatsApp / Telegram', phone] if phone.present?
    lines << ['Email', email]
    lines << ['Price', price_label] if price.present?
    lines << ['Comments', comments] if comments.present?
    lines
  end

  # Письма клиенту (подтверждение) и администратору (новая заявка).
  # Ошибки почты не должны ломать отправку формы — только логируем.
  def notify!
    ServiceRequestMailer.client_confirmation(self).deliver_now
    ServiceRequestMailer.admin_notification(self).deliver_now
  rescue StandardError => e
    Rails.logger.error("ServiceRequest##{id} notify failed: #{e.class}: #{e.message}")
  end

  def kind_title_en
    { 'insurance' => 'Medical insurance for Russia',
      'train'     => 'Train tickets',
      'vip'       => 'VIP Meet-and-Greet & Border Support (Moscow)' }[kind] || kind
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id kind status full_name email phone citizenship passport_number date_from date_to price
       currency comments manager_notes invitation_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[invitation]
  end

  private

  def fmt(date)
    date&.strftime('%d.%m.%Y')
  end

  def normalize_fields
    self.email       = email.to_s.strip.downcase.presence
    self.citizenship = citizenship.to_s.strip.upcase.presence
    self.passport_number = passport_number.to_s.strip.presence
    self.full_name   = full_name.to_s.squish.presence
    self.passengers  = passengers.to_s.strip.presence if passengers
    self.passengers  = '1' if (train? || vip?) && passengers.blank?
  end

  def assign_price
    case kind
    when 'insurance'
      days = insurance_days
      self.price = (days * self.class.insurance_rate(citizenship)).round(2) if days&.positive?
    when 'vip'
      self.price = VIP_PRICE
    else
      self.price = nil # ЖД: цену менеджер сообщает в переписке
    end
    self.currency = 'usd'
  end

  def insurance_period_is_valid
    return if date_from.blank? || date_to.blank?

    if date_to < date_from || !insurance_days.between?(1, INSURANCE_MAX_DAYS)
      errors.add(:base, "Insurance period must be from 1 to #{INSURANCE_MAX_DAYS} days")
    end
  end

  # Либо данные паспорта заполнены, либо приложена копия паспорта.
  def insurance_person_given
    return if passport_copy.attached?
    return if full_name.present? && passport_number.present?

    errors.add(:base, 'Please fill in your full name and passport number, or attach a copy of your passport')
  end

  def passport_copy_attached
    errors.add(:passport_copy, 'is required') unless passport_copy.attached?
  end

  def passengers_in_range
    n = Integer(passengers.to_s, exception: false)
    errors.add(:passengers, "must be from 1 to #{MAX_PASSENGERS}") unless n&.between?(1, MAX_PASSENGERS)
  end

  def trip_date_not_in_past
    return if date_from.blank?

    errors.add(:date_from, "can't be in the past") if date_from < Time.zone.today
  end

  def attachments_are_valid
    { passport_copy: passport_copy, visa_copy: visa_copy }.each do |name, file|
      next unless file.attached?

      blob = file.blob
      unless ALLOWED_CONTENT_TYPES.include?(blob.content_type)
        errors.add(name, 'must be a JPG, PNG, HEIC or PDF file')
      end
      errors.add(name, 'must be smaller than 10 MB') if blob.byte_size > MAX_FILE_SIZE
    end
  end
end
