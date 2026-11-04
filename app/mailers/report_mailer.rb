class ReportMailer < ApplicationMailer
  # Ежедневная сводка по приглашениям для администратора.
  # Получатель: REPORT_TO_EMAIL (можно несколько через запятую), иначе SMTP_TO_EMAIL.
  def daily_summary(report)
    @report = report
    recipients = (ENV['REPORT_TO_EMAIL'].presence || ENV['SMTP_TO_EMAIL']).to_s.split(',').map(&:strip).reject(&:empty?)
    mail(to: recipients,
         subject: "Сводка по приглашениям #{report.period_label}: #{report.total} шт.")
  end
end
