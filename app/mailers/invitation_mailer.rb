class InvitationMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.invitation_mailer.new_order.subject
  #
  def new_order(invitation)
    @order_date = invitation.created_at
    @order_number = invitation.id
    @order_url = "https://#{$SITE_HOST}/#{ENV['ADMIN_URL']}/invitations/#{@order_number}"

    mail(to: ENV["SMTP_TO_EMAIL"], subject: "New application on the website")
  end
end
