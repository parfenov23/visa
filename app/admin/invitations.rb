ActiveAdmin.register Invitation do
  # Разрешённые параметры для формы
  permit_params :invitation_type_id, :surname, :name, :middlename, :sex,
                :citizenship, :birthDate, :arival_date, :departure_date,
                :passport, :visa_obtain_place, :cities, :hotels, :hotels_ru,
                :email, :promocode, :comments, :accomodation, :meals, :price, :currency, :tariff

  action_item :pdf, only: :show do
    link_to "Invoice PDF", invitation_path(resource, format: :pdf), target: "_blank"
  end

  index do
    selectable_column
    id_column
    column :email
    column :tariff
    column :price
    column :currency
    column :promocode
    column :surname
    column :name
    column :citizenship_title
    column :birthDate
    column :arival_date
    column :departure_date
    actions
  end

  # -----------------------------
  # Фильтры в админке
  # -----------------------------
  filter :surname
  filter :name
  filter :citizenship
  filter :passport
  filter :arival_date
  filter :departure_date
  filter :created_at

  # -----------------------------
  # Форма редактирования
  # -----------------------------
  form do |f|
    f.semantic_errors

    f.inputs "Invitation Details" do
      f.input :price
      f.input :surname
      f.input :name
      f.input :middlename
      f.input :sex, as: :select, collection: [["Male", 1], ["Female", 0]]
      f.input :citizenship
      f.input :birthDate, label: "Date of birth"
      f.input :arival_date, label: "Arrival date"
      f.input :departure_date, label: "Departure date"
      f.input :passport
      f.input :visa_obtain_place
      f.input :cities
      f.input :hotels
      f.input :hotels_ru
      f.input :accomodation, as: :select, collection: Invitation::ALL_ACCOMODATION
      f.input :meals, as: :select, collection: Invitation::ALL_MEALS
      f.input :email
      f.input :promocode
      f.input :comments
    end

    f.actions
  end

  # -----------------------------
  # Show page (страница просмотра)
  # -----------------------------
  show do
    attributes_table do
      row :id
      row :package
      row :tariff
      row :currency
      row :surname
      row :name
      row :middlename
      row :sex
      row :citizenship_title
      row :birthDate
      row :arival_date
      row :departure_date
      row :passport
      row :visa_obtain_place
      row :cities
      row :hotels
      row :accomodation
      row :meals
      row :email
      row :promocode do |inv|
        raw "<b style='color: red;'>#{inv.promocode}</b>"
      end
      row :comments
      row :created_at
      row :updated_at
    end
  end
end