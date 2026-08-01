class Hotel < ApplicationRecord
  validates :name, presence: true

  default_scope { order(:name) }

  # Название для отображения в выпадающем списке: "EN name (RU name), City".
  def display_label
    [name, name_ru.presence && "(#{name_ru})", city.presence].compact.join(" ").strip
  end

  # Данные для JS-подстановки в форме приглашения.
  def as_picker_option
    { label: display_label, en: name.to_s, ru: name_ru.to_s }
  end

  def self.picker_options
    all.map(&:as_picker_option)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name name_ru city address created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
