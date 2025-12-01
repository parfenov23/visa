require 'logger'
require 'json'

CHANNEL_LOGGER = Logger.new(
  Rails.root.join('log/channels.log'),
  7,                    # количество ротаций
  50 * 1024 * 1024      # размер файла (50 МБ)
)

# Чтобы каждая строка была чистым JSON (одна запись = одна строка)
CHANNEL_LOGGER.formatter = proc do |severity, datetime, _progname, msg|
  payload = msg.is_a?(Hash) ? msg : { message: msg }
  payload.merge!(
    severity:,
    timestamp: datetime.utc.iso8601
  )
  "#{payload.to_json}\n"
end
