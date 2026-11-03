class ApplicationMailer < ActionMailer::Base
  # Лямбда: адрес читается при отправке, а не при загрузке класса.
  default from: -> { ENV['SMTP_TO_EMAIL'] }
  layout 'mailer'
end

