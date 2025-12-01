class CreateInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :invitations do |t|
      t.string :tariff
      t.string :package
      t.string :surname
      t.string :name
      t.string :middlename
      t.string :sex
      t.string :citizenship
      t.string :birthDate
      t.string :arival_date
      t.string :departure_date
      t.string :passport
      t.text :visa_obtain_place
      t.text :cities
      t.text :hotels
      t.text :hotels_ru
      t.string :offname
      t.string :email
      t.string :website
      t.string :promocode
      t.text :comments
      t.text :currency
      t.float :price
      t.string :accomodation
      t.string :meals

      t.timestamps
    end
  end
end
