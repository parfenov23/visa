# app/controllers/invitations_controller.rb
class InvitationsController < ApplicationController
  skip_forgery_protection only: :create
  # Личные документы и страница верификации не должны попадать в поисковый индекс.
  before_action -> { response.set_header("X-Robots-Tag", "noindex, nofollow") }, only: [:show, :verify]

  RATE_LIMIT_WINDOW = 2.minutes

  def create
    # if submission_rate_limited?
    #   redirect_to root_path(tariff: params[:tariff].presence),
    #               notice: "We already received an application from your IP. Please try again in a couple of minutes."
    #   return
    # end

    @invitation = Invitation.new(invitation_params)

    popup = "submission_error"
    # Turnstile temporarily disabled; anti-spam is enforced via Redis rate-limit below.!
    is_dev = Rails.env.development?
    cf_verify = (is_dev || verify_turnstile(model: @invitation))
    if (is_dev || cf_verify.success?) && @invitation.save
      @invitation.send_notify_email
      # mark_submission!
      popup = "submission_success"
    end

    flash[:popup] = popup
    redirect_to root_path(tariff: params[:tariff].presence)
  end

  def show
    @invitation = Invitation.find(params[:id])

    @seal_ru_base64 = encode_sign(@invitation.seal_left)
    @seal_en_base64 = encode_sign(@invitation.seal_right)
    @logo_base64    = encode_image("fortuna_logo.png")

    # Фича-флаг QR_VERIFY_ENABLED (по умолчанию включён — новый QR с верификацией).
    # Установите QR_VERIFY_ENABLED=false, чтобы временно вернуть старый статичный QR.
    @qr_verify_enabled = qr_verify_enabled?
    if @qr_verify_enabled
      # Новый QR: ведёт на публичную страницу верификации (ссылка открывается
      # штатной камерой). Бейдж — белая иконка на красном круге поверх центра.
      @qr_logo_base64 = encode_image("fortuna_qr_logo.png")
      @qr_data_uri    = QrCodeGenerator.data_uri(verification_url(@invitation))
    else
      # Старый статичный QR (как было до правки).
      @qr_base64 = encode_image("fortuna_qr.png")
    end

    html = render_to_string(template: "invitations/pdf", formats: [:pdf], layout: false)

    if params[:debug]
      render html: html.html_safe, layout: false
      return
    end

    respond_to do |format|
      format.html { render html: html.html_safe, layout: false }
      format.pdf do
        pdf = PdfRenderer.render(html, landscape: true)
        send_data pdf,
                  filename: "invitation_#{@invitation.id}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  # Публичная страница верификации туриста (открывается по QR из приглашения).
  def verify
    @invitation = Invitation.find_by!(verify_token: params[:token])
    render layout: false
  rescue ActiveRecord::RecordNotFound
    render plain: "Invitation not found", status: :not_found
  end

  private

  # Фича-флаг нового QR с верификацией. По умолчанию включён.
  # Выключить (вернуть старый статичный QR): QR_VERIFY_ENABLED=false.
  def qr_verify_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("QR_VERIFY_ENABLED", "true"))
  end

  # Абсолютный URL страницы верификации с подписанным токеном приглашения.
  # Домен: VERIFY_BASE_URL, иначе выделенный QR-домен в проде и текущий хост в dev
  # (чтобы ссылку из QR можно было проверить локально — localhost/LAN/ngrok).
  def verification_url(invitation)
    base = (ENV["VERIFY_BASE_URL"].presence || default_verify_base).sub(%r{/+\z}, "")
    "#{base}/verify/#{invitation.verify_token}"
  end

  def default_verify_base
    Rails.env.production? ? "https://fortunatravel.in" : request.base_url
  end

  def encode_image(filename)
    Base64.strict_encode64(File.read(Rails.root.join("app/assets/images", filename)))
  end

  # Encodes a seal from public/signs/<n>.png. Falls back to a random valid seal
  # for legacy invitations created before seals were persisted.
  def encode_sign(number)
    n = number.to_i
    n = rand(1..Invitation::SEALS_COUNT) unless n.between?(1, Invitation::SEALS_COUNT)
    Base64.strict_encode64(File.read(Rails.root.join("public/signs", "#{n}.png")))
  end

  def submission_rate_limited?
    redis_client.exists?(rate_limit_key)
  rescue Redis::BaseError => e
    Rails.logger.warn("Rate-limit check skipped: #{e.class}: #{e.message}")
    false
  end

  def mark_submission!
    redis_client.set(rate_limit_key, Time.now.to_i, ex: RATE_LIMIT_WINDOW.to_i)
  rescue Redis::BaseError => e
    Rails.logger.warn("Rate-limit write skipped: #{e.class}: #{e.message}")
  end

  def rate_limit_key
    "invitation_submit:#{request.remote_ip}"
  end

  def redis_client
    @redis_client ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/2"))
  end

  def invitation_params
    params.permit(
      :package, :surname, :name, :middlename, :sex,
      :citizenship, :birthDate, :arival_date, :departure_date,
      :passport, :visa_obtain_place, :cities, :hotels, :offname,
      :email, :website, :promocode, :comments, :currency, :tariff
    )
  end
end