ActiveAdmin.register Invitation do
  # Разрешённые параметры для формы
  permit_params :invitation_type_id, :surname, :name, :middlename, :sex,
                :citizenship, :birthDate, :arival_date, :departure_date, :package,
                :passport, :visa_obtain_place, :cities, :hotels, :hotels_ru, :hotel_picker,
                :email, :promocode, :comments, :accomodation, :meals, :price, :currency, :tariff,
                :purpose, :status, :additional_info, :seal_left, :seal_right,
                :agency, :seal_high, :print_seal, :cancel_reason

  # Заявки не удаляем — дубли и отказы помечаются статусами «Повторная» / «Отказ».
  actions :all, except: [:destroy]

  action_item :pdf, only: :show do
    link_to "Invoice PDF", invitation_path(resource, format: :pdf), target: "_blank"
  end

  # Разовая выгрузка без печати и подписи (для оригиналов), не меняя саму заявку.
  action_item :pdf_no_seal, only: :show do
    link_to "PDF без печати", invitation_path(resource, format: :pdf, no_seal: 1), target: "_blank"
  end

  batch_action :destroy, false

  batch_action :mark_duplicate, confirm: "Отметить выбранные заявки как повторные?" do |ids|
    batch_action_collection.where(id: ids).update_all(status: 'duplicate', updated_at: Time.current)
    redirect_to collection_path, notice: "Отмечено как повторные: #{ids.size}"
  end

  batch_action :mark_cancelled, confirm: "Отметить выбранные заявки как отказ / аннулированные?" do |ids|
    batch_action_collection.where(id: ids).update_all(status: 'cancelled', updated_at: Time.current)
    redirect_to collection_path, notice: "Отмечено как отказ: #{ids.size}"
  end

  index do
    selectable_column
    id_column
    column('Status') do |inv|
      label = Invitation::STATUSES[inv.status] || inv.status
      color = Invitation::STATUS_COLORS.fetch(inv.status, '#2563eb')
      status_tag label, style: "background-color: #{color}; color: #fff;"
    end
    column('Агентство') { |inv| inv.agency? ? status_tag('Агентство', style: 'background-color: #7c3aed; color: #fff;') : '' }
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
  filter :id
  filter :email
  filter :invitation_number,
         as: :string,
         label: 'Invitation number (10 цифр)'
  filter :surname
  filter :name
  filter :citizenship
  filter :passport
  filter :arival_date
  filter :departure_date
  filter :purpose, as: :select, collection: Invitation::PURPOSES.invert
  filter :status, as: :select, collection: Invitation::STATUSES.invert
  filter :agency, as: :select, label: 'Турагентство / фирма', collection: [['Да', true], ['Нет', false]]

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

    render partial: "admin/invitations/hotel_datalist"

    f.inputs "Invitation Details" do
      f.input :price
      f.input :package, as: :select, collection: Invitation.tariff_price(currency: f.object.currency.to_sym, tariff: f.object.tariff.to_sym).keys
      f.input :purpose, as: :select, collection: Invitation::PURPOSES.invert, include_blank: false, label: 'Purpose of visit'
      f.input :status, as: :select, collection: Invitation::STATUSES.invert, include_blank: false,
              hint: 'Duplicate — повторная заявка, Cancelled — клиент отказался (например, из-за ошибки). Такие заявки не удаляются, но не попадают в статистику и рассылки.'
      f.input :cancel_reason, as: :text, input_html: { rows: 2 },
              label: 'Причина аннуляции',
              hint: 'Для статусов Duplicate / Cancelled, например: «ошибка в паспорте, клиент переоформил».'
      f.input :agency, as: :boolean, label: 'Турагентство / фирма (не отправлять автоматические письма)'
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
      f.input :hotel_picker,
              as: :string,
              label: 'Гостиница из базы (поиск и подстановка)',
              input_html: {
                id: 'hotel_picker_input',
                list: 'hotels_datalist',
                autocomplete: 'off',
                placeholder: 'Начните вводить название…'
              },
              hint: 'Каждая выбранная гостиница добавляется новой строкой в поля Hotels (EN) и Hotels (RU) ниже — можно выбрать несколько подряд. Базу можно вести в разделе «Hotels (база)».'
      f.input :hotels, label: 'Hotels (EN)'
      f.input :hotels_ru, label: 'Hotels (RU)'
      f.input :accomodation, as: :select, collection: Invitation::ALL_ACCOMODATION
      f.input :meals, as: :select, collection: Invitation::ALL_MEALS, default: "RO"
      f.input :email
      f.input :promocode
      f.input :comments
      f.input :additional_info,
              as: :text,
              input_html: { rows: 3 },
              hint: 'Будет добавлено к строке "индивидуальный тур" в PDF (Дополнительные сведения).'
      f.input :seal_left,  as: :select, collection: (1..Invitation::SEALS_COUNT).to_a,
              include_blank: false, label: 'Печать (левая / RU)'
      f.input :seal_right, as: :select, collection: (1..Invitation::SEALS_COUNT).to_a,
              include_blank: false, label: 'Печать (правая / EN)',
              hint: 'Печати должны быть разными.'
      f.input :seal_high, as: :boolean,
              label: 'Печать высоко (когда гостиниц больше 4)'
      f.input :print_seal, as: :boolean,
              label: 'Печать и подпись в PDF',
              hint: 'Снимите галочку для выдачи оригиналов — печать и подпись ставятся вручную.'
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
      row('Причина аннуляции') { |inv| inv.cancel_reason } if resource.cancel_reason.present?
      row('Турагентство / фирма') { |inv| inv.agency? ? 'Да' : 'Нет' }
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
      row('Печати (лев./прав.)') { |inv| "#{inv.seal_left} + #{inv.seal_right}" }
      row('Печать высоко') { |inv| inv.seal_high? ? 'Да' : 'Нет' }
      row('Печать и подпись в PDF') { |inv| inv.print_seal? ? 'Да' : 'Нет (оригинал)' }
      row(:created_at) { |inv| inv.created_at&.strftime('%d.%m.%Y %H.%M.%S') }
      row(:updated_at) { |inv| inv.updated_at&.strftime('%d.%m.%Y %H.%M.%S') }
    end
  end
end