# frozen_string_literal: true

# Автоотправка писем с предложениями (галочки в заявке) через 5 минут после Done.
# Выключить автоотправку: UPSELL_EMAILS_ENABLED=off (ручная кнопка в админке работает).
class OffersDelivery
  def self.enabled?
    ENV.fetch('UPSELL_EMAILS_ENABLED', 'on').to_s.downcase != 'off'
  end

  def self.deliver_due(logger: Rails.logger)
    return 0 unless enabled?

    sent = 0
    Invitation.offers_due.find_each do |inv|
      keys = inv.deliver_offers!
      next if keys.empty?

      sent += 1
      logger.info("[offers] invitation ##{inv.id}: sent #{keys.join(', ')}")
    rescue StandardError => e
      logger.error("[offers] invitation ##{inv.id}: #{e.class}: #{e.message}")
    end
    sent
  end
end
