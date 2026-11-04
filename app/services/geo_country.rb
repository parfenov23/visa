# frozen_string_literal: true

require "ipaddr"
require "csv"
require "zlib"
require "net/http"
require "fileutils"

# Определение страны посетителя по IP (сайт работает без Cloudflare-прокси,
# поэтому заголовка CF-IPCountry нет).
#
# Источник — бесплатная база DB-IP «IP to Country Lite» (CC BY 4.0, без ключа):
# https://db-ip.com/db/download/ip-to-country-lite. Из неё сохраняются только
# диапазоны нужных стран (COUNTRIES) в небольшой CSV: storage/geo/country_ranges.csv.
# Файл обновляется раз в месяц планировщиком (GeoCountry.update!) или вручную:
#   bundle exec rails geo:update
#
#   GeoCountry.lookup("49.36.0.1")  # => "IN"
#   GeoCountry.india?("8.8.8.8")    # => false
class GeoCountry
  COUNTRIES   = %w[IN NP].freeze
  SOURCE_URL  = "https://download.db-ip.com/free/dbip-country-lite-%<month>s.csv.gz"
  MAX_AGE     = 30 * 24 * 3600 # обновлять, если файлу больше 30 дней
  RELOAD_EVERY = 600           # как часто проверять, не обновился ли файл (сек)

  class << self
    def path
      Pathname.new(ENV["GEO_COUNTRY_FILE"].presence || Rails.root.join("storage/geo/country_ranges.csv"))
    end

    def lookup(ip)
      instance.lookup(ip)
    end

    def india?(ip)
      lookup(ip) == "IN"
    end

    def instance
      @instance = nil if @instance && @instance.path != path
      @instance ||= new(path)
    end

    def stale?(file = path)
      !File.exist?(file) || Time.now - File.mtime(file) > MAX_AGE
    end

    # Скачивает базу DB-IP за текущий месяц (или за прошлый, если текущий ещё не
    # опубликован) и сохраняет диапазоны COUNTRIES. Возвращает число диапазонов.
    def update!(file = path, today: Date.today)
      months = [today, today.prev_month].map { |d| d.strftime("%Y-%m") }
      last_error = nil
      months.each do |month|
        url = format(SOURCE_URL, month: month)
        begin
          return download(url, file)
        rescue StandardError => e
          last_error = e
        end
      end
      raise last_error
    end

    def update_if_stale!(file = path)
      stale?(file) ? update!(file) : nil
    end

    # Отбирает из CSV базы DB-IP (start,end,country) строки нужных стран.
    def extract(io, out)
      count = 0
      io.each_line do |line|
        start_ip, end_ip, code = CSV.parse_line(line)
        next unless code && COUNTRIES.include?(code.strip.upcase)

        out << "#{start_ip.strip},#{end_ip.strip},#{code.strip.upcase}\n"
        count += 1
      end
      count
    end

    private

    def download(url, file)
      FileUtils.mkdir_p(File.dirname(file))
      gz  = "#{file}.download.gz"
      tmp = "#{file}.tmp"

      uri = URI(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 20, read_timeout: 120) do |http|
        http.request(Net::HTTP::Get.new(uri)) do |response|
          raise "GeoCountry: #{url} -> HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          File.open(gz, "wb") { |f| response.read_body { |chunk| f.write(chunk) } }
        end
      end

      count = Zlib::GzipReader.open(gz) do |input|
        File.open(tmp, "w") { |out| extract(input, out) }
      end
      raise "GeoCountry: no ranges for #{COUNTRIES.join(', ')} in #{url}" if count.zero?

      File.rename(tmp, file)
      count
    ensure
      [gz, tmp].each { |f| File.delete(f) if f && File.exist?(f) }
    end
  end

  attr_reader :path

  def initialize(path)
    @path = Pathname.new(path)
    @loaded_mtime = nil
    @checked_at = nil
    @ranges = { 4 => [], 6 => [] }
  end

  def lookup(ip)
    reload_if_changed
    addr = IPAddr.new(ip.to_s)
    addr = addr.native if addr.ipv4_mapped?
    family = addr.ipv4? ? 4 : 6
    value = addr.to_i
    ranges = @ranges[family]
    idx = ranges.bsearch_index { |(_, last, _)| last >= value }
    return nil unless idx

    first, _last, code = ranges[idx]
    value >= first ? code : nil
  rescue IPAddr::Error, ArgumentError
    nil
  end

  private

  def reload_if_changed
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    return if @checked_at && now - @checked_at < RELOAD_EVERY && @loaded_mtime

    @checked_at = now
    mtime = File.exist?(path) ? File.mtime(path) : nil
    return if mtime.nil? || mtime == @loaded_mtime

    load_ranges
    @loaded_mtime = mtime
  end

  # Диапазоны в базе не пересекаются; сортируем по началу для двоичного поиска.
  def load_ranges
    ranges = { 4 => [], 6 => [] }
    File.foreach(path) do |line|
      start_ip, end_ip, code = line.strip.split(",")
      next if code.nil?

      first = IPAddr.new(start_ip)
      ranges[first.ipv4? ? 4 : 6] << [first.to_i, IPAddr.new(end_ip).to_i, code]
    rescue IPAddr::Error
      next
    end
    ranges.each_value { |list| list.sort_by!(&:first) }
    @ranges = ranges
  end
end
