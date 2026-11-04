# Напоминание клиенту за несколько дней до приезда: получил ли визу, всё ли в силе.
class ReminderMailer < ApplicationMailer
  def arrival_reminder(invitation)
    @invitation = invitation
    mail(to: invitation.email, subject: 'Your trip to Russia is coming up — please confirm your status')
  end
end
