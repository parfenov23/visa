namespace :geo do
  desc "Скачать базу IP-адресов DB-IP и сохранить диапазоны Индии и Непала (storage/geo/country_ranges.csv)"
  task update: :environment do
    count = GeoCountry.update!
    puts "GeoCountry: сохранено диапазонов: #{count} -> #{GeoCountry.path}"
  end

  desc "Определить страну по IP: rails geo:lookup IP=49.36.0.1"
  task lookup: :environment do
    puts GeoCountry.lookup(ENV.fetch("IP")).inspect
  end
end
