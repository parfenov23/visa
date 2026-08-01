class CreateHotels < ActiveRecord::Migration[7.0]
  def change
    create_table :hotels do |t|
      t.string :name,    null: false           # название (EN) — подставляется в hotels
      t.string :name_ru                        # название (RU) — подставляется в hotels_ru
      t.string :city                            # город (для удобного поиска/фильтра)
      t.string :address                         # адрес (опционально)

      t.timestamps
    end

    add_index :hotels, :name
    add_index :hotels, :city
  end
end
