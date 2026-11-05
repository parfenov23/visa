# Заявки на доп. услуги: страховка, ЖД билеты, VIP-встреча.
ActiveAdmin.register ServiceRequest do
  menu label: "Доп. услуги", priority: 3

  actions :all, except: [:new, :create, :destroy]
  config.sort_order = "created_at_desc"

  permit_params :status, :full_name, :email, :phone, :citizenship, :passport_number,
                :date_from, :date_to, :price, :comments, :manager_notes,
                :from_city, :to_city, :departure_time, :seat_class, :passengers,
                :arrival_time, :flight_number, :hotel_address, :invitation_ref,
                *ServiceRequest::VIP_CHECKLIST.keys

  # Название — лямбдой, id — вторым аргументом: русские названия при parameterize
  # превращаются в пустую строку, и вкладки затирали друг друга.
  scope(-> { "Все" }, :all, default: true)
  ServiceRequest::KINDS.each do |kind, title|
    scope(-> { title }, kind) { |s| s.where(kind: kind) }
  end

  batch_action :destroy, false

  filter :kind, as: :select, label: "Услуга", collection: ServiceRequest::KINDS.invert
  filter :status, as: :select, label: "Статус", collection: ServiceRequest::STATUSES.invert
  filter :email
  filter :full_name
  filter :citizenship
  filter :date_from, label: "Дата поездки / прилёта"
  filter :created_at

  index do
    selectable_column
    id_column
    column("Услуга") { |r| r.kind_title }
    column("Статус") do |r|
      status_tag r.status_title, style: "background-color: #{ServiceRequest::STATUS_COLORS.fetch(r.status, '#2563eb')}; color: #fff;"
    end
    column :full_name
    column :email
    column("Гражданство") { |r| r.citizenship_title }
    column("Даты") do |r|
      [r.date_from, r.date_to].compact.map { |d| d.strftime('%d.%m.%Y') }.join(" — ")
    end
    column("Детали") do |r|
      case r.kind
      when "train" then "#{r.from_city} → #{r.to_city}, #{r.seat_class_title}, #{r.passengers} пасс."
      when "vip"   then "Рейс #{r.flight_number} #{r.arrival_time}"
      when "insurance" then "#{r.insurance_days} дн."
      end
    end
    column("Цена") { |r| r.price_label }
    column("Документы") do |r|
      [(link_to("паспорт", rails_blob_path(r.passport_copy, disposition: "attachment")) if r.passport_copy.attached?),
       (link_to("виза", rails_blob_path(r.visa_copy, disposition: "attachment")) if r.visa_copy.attached?)]
        .compact.join(" · ").html_safe
    end
    column("Создана") { |r| r.created_at.strftime('%d.%m.%Y %H:%M') }
    actions
  end

  show do
    attributes_table do
      row("Услуга") { |r| r.kind_title }
      row("Статус") { |r| r.status_title }
      row("Цена") { |r| r.price_label || "— (сообщает менеджер)" }
      row :full_name
      row :email
      row :phone
      row("Гражданство") { |r| r.citizenship_title }
      row :passport_number
      if resource.insurance?
        row("Период страховки") { |r| "#{r.date_from&.strftime('%d.%m.%Y')} — #{r.date_to&.strftime('%d.%m.%Y')} (#{r.insurance_days} дн.)" }
        row("Ставка") { |r| "USD #{ServiceRequest.insurance_rate(r.citizenship)} / день" }
      end
      if resource.train?
        row("Маршрут") { |r| "#{r.from_city} → #{r.to_city}" }
        row("Дата поездки") { |r| r.date_from&.strftime('%d.%m.%Y') }
        row("Желаемое время") { |r| r.departure_time_title }
        row("Класс") { |r| r.seat_class_title }
        row("Пассажиров") { |r| r.passengers }
      end
      if resource.vip?
        row("Прилёт") { |r| "#{r.date_from&.strftime('%d.%m.%Y')} #{r.arrival_time}" }
        row("Рейс") { |r| r.flight_number }
        row("Отель / адрес") { |r| r.hotel_address }
        row("Пассажиров") { |r| r.passengers }
        row("Номер приглашения (от клиента)") { |r| r.invitation_ref }
      end
      row("Приглашение") do |r|
        link_to("№ #{r.invitation.current_id}", admin_invitation_path(r.invitation)) if r.invitation
      end
      row("Копия паспорта") do |r|
        link_to(r.passport_copy.filename.to_s, rails_blob_path(r.passport_copy, disposition: "attachment")) if r.passport_copy.attached?
      end
      row("Копия визы") do |r|
        link_to(r.visa_copy.filename.to_s, rails_blob_path(r.visa_copy, disposition: "attachment")) if r.visa_copy.attached?
      end
      row :comments
      row("Заметки менеджера") { |r| simple_format(r.manager_notes) if r.manager_notes.present? }
      row(:created_at) { |r| r.created_at.strftime('%d.%m.%Y %H:%M') }
    end

    if resource.vip?
      panel "Чек-лист VIP-встречи" do
        ul do
          ServiceRequest::VIP_CHECKLIST.each do |key, label|
            li "#{resource.public_send(key) ? '✅' : '⬜'} #{label}"
          end
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Заявка: #{f.object.kind_title}" do
      f.input :status, as: :select, collection: ServiceRequest::STATUSES.invert, include_blank: false
      f.input :price, hint: "USD. Для ЖД — укажите после согласования с клиентом."
      f.input :manager_notes, label: "Заметки менеджера", input_html: { rows: 3 }
    end

    if f.object.vip?
      f.inputs "Чек-лист VIP-встречи" do
        ServiceRequest::VIP_CHECKLIST.each do |key, label|
          f.input key, as: :boolean, label: label
        end
      end
    end

    f.inputs "Данные клиента" do
      f.input :full_name
      f.input :email
      f.input :phone
      f.input :citizenship, hint: "Код страны, например IN"
      f.input :passport_number
      f.input :date_from, as: :datepicker, label: (f.object.vip? ? "Дата прилёта" : "Дата начала / поездки")
      f.input :date_to, as: :datepicker, label: "Дата окончания" if f.object.insurance?
      if f.object.train?
        f.input :from_city
        f.input :to_city
        f.input :departure_time, as: :select, collection: ServiceRequest::DEPARTURE_TIMES.invert
        f.input :seat_class, as: :select, collection: ServiceRequest::SEAT_CLASSES.invert
        f.input :passengers
      end
      if f.object.vip?
        f.input :arrival_time
        f.input :flight_number
        f.input :hotel_address
        f.input :passengers
        f.input :invitation_ref, label: "Номер приглашения"
      end
      f.input :comments, input_html: { rows: 3 }
    end
    f.actions
  end
end
