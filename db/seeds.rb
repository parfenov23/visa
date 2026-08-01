AdminUser.create!(email: 'admin@mail.ru', password: 'password', password_confirmation: 'password') if Rails.env.development?

# Стартовая база гостиниц (можно дополнять/редактировать в админке — раздел «Hotels (база)»).
HOTELS_SEED = [
  { name: "Hotel National",              name_ru: "Отель «Националь»",            city: "Moscow" },
  { name: "Metropol Hotel Moscow",       name_ru: "Гостиница «Метрополь»",        city: "Moscow" },
  { name: "Radisson Collection Hotel",   name_ru: "Рэдиссон Коллекшн Отель",      city: "Moscow" },
  { name: "Hotel Astoria",               name_ru: "Отель «Астория»",              city: "Saint Petersburg" },
  { name: "Grand Hotel Europe",          name_ru: "Гранд Отель Европа",           city: "Saint Petersburg" },
  { name: "Lotte Hotel St. Petersburg",  name_ru: "Лотте Отель Санкт-Петербург",  city: "Saint Petersburg" },
  { name: "Azimut Hotel Sochi",          name_ru: "Азимут Отель Сочи",            city: "Sochi" },
  { name: "Swissotel Resort Sochi",      name_ru: "Свиссотель Резорт Сочи",       city: "Sochi" },
  { name: "Kazan Palace by Tasigo",      name_ru: "Казань Палас",                 city: "Kazan" },
  { name: "Grand Hotel Kazan",           name_ru: "Гранд Отель Казань",           city: "Kazan" }
].freeze

HOTELS_SEED.each do |attrs|
  Hotel.find_or_create_by!(name: attrs[:name]) do |h|
    h.name_ru = attrs[:name_ru]
    h.city    = attrs[:city]
  end
end
