# frozen_string_literal: true

# Напоминание клиенту перед приездом: «Получили ли визу? Поездка в силе?».
# Уходит за DAYS_BEFORE дней до даты приезда (ARRIVAL_REMINDER_DAYS, по умолчанию 3),
# один раз, только по заявкам в статусе Done и не от турагентств.
# Если планировщик пропустил день, напоминание уйдёт позже — пока до приезда
# остаётся хотя бы 1 день.
class ArrivalReminder
  def self.days_before
    Integer(ENV.fetch('ARRIVAL_REMINDER_DAYS', 3))
  rescue ArgumentError
    3
  end

  def self.deliver_due(today: Time.zone.today, logger: Rails.logger)
    new(today: today, logger: logger).deliver_due
  end

  def initialize(today:, logger:)
    @today  = today
    @logger = logger
  end

  # Заявки, которым пора отправить напоминание (дата приезда — строка, сравниваем в Ruby).
  def due
    window = (@today + 1)..(@today + self.class.days_before)
    candidates.select do |inv|
      arrival = inv.arrival_on
      if arrival.nil?
        @logger.warn("[arrival_reminder] invitation ##{inv.id}: can't parse arrival date #{inv.arival_date.inspect}")
        next false
      end
      window.cover?(arrival)
    end
  end

  def deliver_due
    sent = 0
    due.each do |inv|
      ReminderMailer.arrival_reminder(inv).deliver_now
      inv.update_columns(reminder_sent_at: Time.current)
      sent += 1
    rescue StandardError => e
      @logger.error("[arrival_reminder] invitation ##{inv.id}: #{e.class}: #{e.message}")
    end
    @logger.info("[arrival_reminder] sent: #{sent}")
    sent
  end

  private

  # Заявка должна быть создана хотя бы сутки назад — иначе клиент получит
  # напоминание сразу вслед за приглашением.
  def candidates
    Invitation.where(status: 'done', agency: false, reminder_sent_at: nil)
              .where.not(email: [nil, ''])
              .where(created_at: 1.year.ago..1.day.ago)
  end
end
