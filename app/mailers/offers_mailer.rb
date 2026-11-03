# Письмо клиенту после оформления приглашения с предложениями, отмеченными
# менеджером галочками в заявке (страховка, VIP-встреча, ЖД билеты…).
class OffersMailer < ApplicationMailer
  def offers(invitation, keys)
    @invitation = invitation
    @keys = keys & Invitation::OFFERS.keys
    @rate = ServiceRequest.insurance_rate(invitation.citizenship)
    @only_vip = @keys == ['vip']

    mail(to: invitation.email, subject: subject_for(@keys))
  end

  private

  def subject_for(keys)
    case keys
    when ['insurance'] then 'Important: medical insurance for your trip to Russia'
    when ['vip']       then 'VIP Meet-and-Greet & Border Support at Moscow airport'
    when ['train']     then 'Train tickets for your trip to Russia'
    else 'Your invitation is ready — useful services for your trip to Russia'
    end
  end
end
