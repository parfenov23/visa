class ApplicationMailer < ActionMailer::Base
  default from: ENV['SMTP_TO_EMAIL']
  layout 'mailer'
end

