class ServiceRequestMailer < ApplicationMailer
  def client_confirmation(service_request)
    @service_request = service_request
    mail(to: service_request.email,
         subject: "Russvisa: we have received your request — #{service_request.kind_title_en}")
  end

  # Администратору: детали заявки и ссылка в админку. Копии паспорта/визы — вложениями.
  def admin_notification(service_request)
    @service_request   = service_request
    @admin_url = "https://#{$SITE_HOST}#{ENV['ADMIN_URL']}/service_requests/#{service_request.id}"
    { passport_copy: service_request.passport_copy, visa_copy: service_request.visa_copy }.each do |name, file|
      next unless file.attached?

      attachments["#{name}_#{file.filename}"] = file.download
    end
    mail(to: ENV['SMTP_TO_EMAIL'], reply_to: service_request.email,
         subject: "Новая заявка: #{service_request.kind_title} — #{service_request.full_name || service_request.email}")
  end
end
