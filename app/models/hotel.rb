class Hotel < ApplicationRecord
  validates :name, presence: true

  default_scope { order(:name) }

  # Короткая подпись для выпадающего списка: "EN name (RU name) City".
  def display_label
    [name, name_ru.presence && "(#{name_ru})", city.presence].compact.join(" ").strip
  end

  # Полная строка (EN) для подстановки в поле Hotels: название + адрес + телефон.
  def full_en
    addr = address.presence
    [
      name.presence,
      ("Address: #{addr}" if addr),
      ("tel. #{phone}" if phone.present?)
    ].compact.join(". ")
  end

  # Полная строка (RU) для подстановки в поле Hotels (RU). С фолбэком на EN-поля.
  def full_ru
    nm   = name_ru.presence || name.presence
    addr = address_ru.presence || address.presence
    [
      nm,
      ("Адрес: #{addr}" if addr),
      ("тел. #{phone}" if phone.present?)
    ].compact.join(". ")
  end

  # Данные для JS-подстановки в форме приглашения.
  def as_picker_option
    { label: display_label, en: full_en, ru: full_ru }
  end

  def self.picker_options
    all.map(&:as_picker_option)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name name_ru city address address_ru phone created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
