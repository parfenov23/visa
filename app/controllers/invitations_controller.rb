# app/controllers/invitations_controller.rb
class InvitationsController < ApplicationController
  skip_forgery_protection only: :create

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
    cf_verify = verify_turnstile(model: @invitation)
    if cf_verify.success? && @invitation.save
      @invitation.send_notify_email
      # mark_submission!
      popup = "submission_success"
    end

    flash[:popup] = popup
    redirect_to root_path(tariff: params[:tariff].presence)
  end

  def show
    @invitation = Invitation.find(params[:id])

    @seal_ru_base64 = encode_image("fortuna_seal_ru.png")
    @seal_en_base64 = encode_image("fortuna_seal_en.png")
    @logo_base64    = encode_image("fortuna_logo.png")
    @qr_base64      = encode_image("fortuna_qr.png")

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

  private

  def encode_image(filename)
    Base64.strict_encode64(File.read(Rails.root.join("app/assets/images", filename)))
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