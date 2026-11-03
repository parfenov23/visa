class ApplicationMailer < ActionMailer::Base
  # Лямбда: адрес читается при отправке, а не при загрузке класса.
  default from: -> { ENV['SMTP_TO_EMAIL'] }
  layout 'mailer'

  helper_method :site_link

  private

  # Абсолютная ссылка на страницу сайта для писем клиентам.
  # Домен: SITE_URL (например https://russvisa.com), иначе RAILS_SERVICE_HOST.
  def site_link(path, **params)
    base = (ENV['SITE_URL'].presence || "https://#{$SITE_HOST}").sub(%r{/+\z}, '')
    query = params.compact.to_query
    "#{base}#{path}#{"?#{query}" if query.present?}"
  end
end
