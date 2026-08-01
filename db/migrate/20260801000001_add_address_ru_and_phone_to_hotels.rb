class AddAddressRuAndPhoneToHotels < ActiveRecord::Migration[7.0]
  def change
    add_column :hotels, :address_ru, :string  # адрес (RU) — подставляется в hotels_ru
    add_column :hotels, :phone, :string        # телефон — подставляется в оба поля
  end
end
