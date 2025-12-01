# app/controllers/invitations_controller.rb
class InvitationsController < ApplicationController
  include WickedPdf::WickedPdfHelper::Assets

  def create
    @invitation = Invitation.new(invitation_params)

    if @invitation.save
      redirect_to root_path, notice: "Invitation created successfully"
    end
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

  def invitation_params
    params.permit(
      :package, :surname, :name, :middlename, :sex,
      :citizenship, :birthDate, :arival_date, :departure_date,
      :passport, :visa_obtain_place, :cities, :hotels, :offname,
      :email, :website, :promocode, :comments, :currency, :tariff
    )
  end
end