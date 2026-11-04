# Письма после оформления приглашения:
# - offers / offers_sent / offers_sent_at — галочки «Предложить клиенту в письме»
#   (страховка, VIP-встреча, ЖД…), что из них уже отправлено и когда;
# - done_at — когда заявку впервые перевели в Done (письмо уходит через 5 минут);
# - reminder_sent_at — напоминание за 3 дня до приезда отправлено.
class AddOffersAndRemindersToInvitations < ActiveRecord::Migration[7.0]
  def change
    add_column :invitations, :offers,           :jsonb, null: false, default: []
    add_column :invitations, :offers_sent,      :jsonb, null: false, default: []
    add_column :invitations, :offers_sent_at,   :datetime
    add_column :invitations, :done_at,          :datetime
    add_column :invitations, :reminder_sent_at, :datetime

    add_index :invitations, :done_at
  end
end
