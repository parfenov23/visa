# Заявки на доп. услуги: страховка, ЖД билеты, VIP-встреча в аэропорту.
# Общие поля — колонками, поля конкретной услуги — в jsonb details,
# чек-лист менеджера (для VIP) — в jsonb checklist.
class CreateServiceRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :service_requests do |t|
      t.string     :kind,            null: false
      t.string     :status,          null: false, default: "new"
      t.string     :full_name
      t.string     :email,           null: false
      t.string     :phone
      t.string     :citizenship
      t.string     :passport_number
      t.date       :date_from
      t.date       :date_to
      t.decimal    :price,           precision: 10, scale: 2
      t.string     :currency,        null: false, default: "usd"
      t.jsonb      :details,         null: false, default: {}
      t.jsonb      :checklist,       null: false, default: {}
      t.text       :comments
      t.text       :manager_notes
      t.references :invitation,      foreign_key: true, null: true
      t.timestamps
    end

    add_index :service_requests, :kind
    add_index :service_requests, :status
    add_index :service_requests, :created_at
  end
end
