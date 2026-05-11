ActiveAdmin.register Invitation do
  # Разрешённые параметры для формы
  permit_params :invitation_type_id, :surname, :name, :middlename, :sex,
                :citizenship, :birthDate, :arival_date, :departure_date, :package,
                :passport, :visa_obtain_place, :cities, :hotels, :hotels_ru,
                :email, :promocode, :comments, :accomodation, :meals, :price, :currency, :tariff,
                :purpose, :status, :additional_info

  action_item :pdf, only: :show do
    link_to "Invoice PDF", invitation_path(resource, format: :pdf), target: "_blank"
  end

  index do
    selectable_column
    id_column
    column('Status') do |inv|
      label = Invitation::STATUSES[inv.status] || inv.status
      color = case inv.status
              when 'done'        then '#1f9d55'
              when 'correction'  then '#d97706'
              else '#2563eb'
              end
      status_tag label, style: "background-color: #{color}; color: #fff;"
    end
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
    column('Purpose') { |inv| Invitation::PURPOSES[inv.purpose] || inv.purpose }
    column('Created at') { |inv| inv.created_at&.strftime('%d.%m.%Y %H.%M.%S') }
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
  filter :purpose, as: :select, collection: Invitation::PURPOSES.invert
  filter :status, as: :select, collection: Invitation::STATUSES.invert

  filter :created_at, as: :date_range, label: 'Created at (range)'

  filter :created_in_period,
         as: :select,
         label: 'Created at (period)',
         collection: [
           ['Today',      'today'],
           ['Yesterday',  'yesterday'],
           ['This week',  'this_week'],
           ['Last week',  'last_week'],
           ['This month', 'this_month'],
           ['Last month', 'last_month']
         ]

  # -----------------------------
  # Форма редактирования
  # -----------------------------
  form do |f|
    f.semantic_errors

    f.inputs "Invitation Details" do
      f.input :price
      f.input :package, as: :select, collection: Invitation.tariff_price(currency: f.object.currency.to_sym, tariff: f.object.tariff.to_sym).keys
      f.input :purpose, as: :select, collection: Invitation::PURPOSES.invert, include_blank: false, label: 'Purpose of visit'
      f.input :status, as: :select, collection: Invitation::STATUSES.invert, include_blank: false
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
      f.input :additional_info,
              as: :text,
              input_html: { rows: 3 },
              hint: 'Будет добавлено к строке "индивидуальный тур" в PDF (Дополнительные сведения).'
    end

    f.actions
  end

  # -----------------------------
  # Show page (страница просмотра)
  # -----------------------------
  show do
    attributes_table do
      row :id
      row('Status') { |inv| Invitation::STATUSES[inv.status] || inv.status }
      row :package
      row :tariff
      row :currency
      row('Purpose of visit') { |inv| Invitation::PURPOSES[inv.purpose] || inv.purpose }
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
      row :additional_info
      row(:created_at) { |inv| inv.created_at&.strftime('%d.%m.%Y %H.%M.%S') }
      row(:updated_at) { |inv| inv.updated_at&.strftime('%d.%m.%Y %H.%M.%S') }
    end
  end
end