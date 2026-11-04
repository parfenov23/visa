# Первый этап доработок:
# - agency       — заявка от турагентства/фирмы (ставится вручную, такие заявки
#                  не получают автоматических писем);
# - seal_high    — печати в PDF ставятся максимально высоко (когда гостиниц > 4);
# - print_seal   — выводить ли печать с подписью в PDF (false — для оригиналов);
# - cancel_reason — причина аннуляции/пометки «повторная».
class AddStage1FieldsToInvitations < ActiveRecord::Migration[7.0]
  def change
    add_column :invitations, :agency,        :boolean, default: false, null: false
    add_column :invitations, :seal_high,     :boolean, default: false, null: false
    add_column :invitations, :print_seal,    :boolean, default: true,  null: false
    add_column :invitations, :cancel_reason, :text

    add_index :invitations, :agency
  end
end
