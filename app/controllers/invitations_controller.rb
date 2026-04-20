# app/controllers/invitations_controller.rb
class InvitationsController < ApplicationController
  include WickedPdf::WickedPdfHelper::Assets
  skip_forgery_protection only: :create

  RATE_LIMIT_WINDOW = 2.minutes

  def create
    if submission_rate_limited?
      redirect_to root_path(tariff: params[:tariff].presence),
                  notice: "We already received an application from your IP. Please try again in a couple of minutes."
      return
    end

    @invitation = Invitation.new(invitation_params)

    notice = "There was a problem submitting your application. Please try again."
    # Turnstile temporarily disabled; anti-spam is enforced via Redis rate-limit below.
    # cf_verify = verify_turnstile(model: @invitation)
    # if cf_verify.success?
    if @invitation.save
      @invitation.send_notify_email
      mark_submission!
      notice = "Thank you for submitting your application at russvisa.com. We will send a payment link to provided email address. For any questions, please contact manager@russvisa.com"
    end
    # end

    redirect_to root_path(tariff: params[:tariff].presence), notice: notice
  end

  def show
    @invitation = Invitation.find(params[:id])
    path = Rails.root.join("app/assets/images/seal.png")
    image_data = File.read(path)
    @seal_base64 = Base64.strict_encode64(image_data)

    path = Rails.root.join("app/assets/images/seal_1.png")
    image_data = File.read(path)
    @seal_2_base64 = Base64.strict_encode64(image_data)

    path = Rails.root.join("app/assets/images/logo-cb.png")
    image_data = File.read(path)
    @logo_base64 = Base64.strict_encode64(image_data)

    if params[:debug]
      erb = ERB.new(File.read(Rails.root.join("app/views/invitations/pdf.pdf.erb")))
      html = erb.result(binding)
      render html: html.html_safe, layout: false
      return
    end

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "invitation_#{@invitation.id}",
               template: "invitations/pdf",
               orientation: "Landscape"
      end
    end
  end

  private

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