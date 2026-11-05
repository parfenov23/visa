ActiveAdmin.register Invitation do
  # Разрешённые параметры для формы
  permit_params :invitation_type_id, :surname, :name, :middlename, :sex,
                :citizenship, :birthDate, :arival_date, :departure_date, :package,
                :passport, :visa_obtain_place, :cities, :hotels, :hotels_ru, :hotel_picker,
                :email, :promocode, :comments, :accomodation, :meals, :price, :currency, :tariff,
                :purpose, :status, :additional_info, :seal_left, :seal_right,
                :agency, :seal_high, :print_seal, :cancel_reason, offers: []

  # Заявки не удаляем — дубли и отказы помечаются статусами «Повторная» / «Отказ».
  actions :all, except: [:destroy]

  action_item :pdf, only: :show do
    link_to "Invoice PDF", invitation_path(resource, format: :pdf), target: "_blank"
  end

  # Разовая выгрузка без печати и подписи (для оригиналов), не меняя саму заявку.
  action_item :pdf_no_seal, only: :show do
    link_to "PDF без печати", invitation_path(resource, format: :pdf, no_seal: 1), target: "_blank"
  end

  # Ручная отправка письма с предложениями (только ещё не отправленные блоки).
  member_action :send_offers, method: :post do
    keys = resource.deliver_offers!
    if keys.any?
      labels = keys.map { |k| Invitation::OFFERS.dig(k, :label) }.join(', ')
      redirect_to resource_path, notice: "Письмо с предложениями отправлено: #{labels}"
    else
      redirect_to resource_path, alert: "Нечего отправлять: отметьте галочки в заявке (уже отправленные блоки повторно не уходят)."
    end
  rescue StandardError => e
    redirect_to resource_path, alert: "Не удалось отправить письмо: #{e.message}"
  end

  action_item :send_offers, only: :show do
    if resource.pending_offers.any?
      link_to "Отправить предложения сейчас", send_offers_admin_invitation_path(resource), method: :post,
              data: { confirm: "Отправить клиенту письмо с отмеченными предложениями?" }
    end
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
    column('Предложения') do |inv|
      # Зелёный — уже отправлено, серый — отмечено, но ещё не ушло.
      Array(inv.offers).each do |key|
        sent = Array(inv.offers_sent).include?(key)
        label = Invitation::OFFERS.dig(key, :label).to_s.split(' ').first
        status_tag(label, style: "background-color: #{sent ? '#1f9d55' : '#9ca3af'}; color: #fff; margin-right: 2px;",
                          title: sent ? 'Отправлено' : 'Ещё не отправлено')
      end
      nil
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
      f.input :price, hint: (f.object.new_record? ? 'Можно не заполнять — посчитается по валюте, тарифу и пакету.' : nil)
      # У новой заявки валюта и тариф ещё не заданы — выбираются здесь.
      if f.object.new_record?
        f.input :currency, as: :select, collection: Invitation.currencies, include_blank: false
        f.input :tariff, as: :select, collection: Invitation.tariffs, include_blank: false
      end
      f.input :package, as: :select, collection: Invitation.packages_for(currency: f.object.currency, tariff: f.object.tariff)
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
      f.input :accomodation, label: 'Accommodation', as: :select, collection: Invitation::ALL_ACCOMODATION
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

    f.inputs 'Предложить клиенту в письме' do
      sent = Array(f.object.offers_sent)
      f.input :offers, as: :check_boxes, label: false,
              collection: Invitation.enabled_offers.map { |key, o| [sent.include?(key) ? "#{o[:label]} — уже отправлено" : o[:label], key] },
              hint: "Письмо уходит клиенту через 5 минут после перевода заявки в Done — только с отмеченными блоками. " \
                    "Турагентствам письмо не отправляется. Если отметить галочку позже — нажмите «Отправить предложения сейчас» в карточке заявки."
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
      row('Accommodation') { |inv| inv.accomodation }
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
      row('Предложения в письме') do |inv|
        sent = Array(inv.offers_sent)
        Array(inv.offers).map { |k| "#{Invitation::OFFERS.dig(k, :label)}#{' ✅' if sent.include?(k)}" }.join(', ').presence || '—'
      end
      row('Письмо с предложениями') { |inv| inv.offers_sent_at ? inv.offers_sent_at.strftime('%d.%m.%Y %H:%M') : 'не отправлено' }
      row('Done') { |inv| inv.done_at&.strftime('%d.%m.%Y %H:%M') }
      row('Напоминание перед приездом') { |inv| inv.reminder_sent_at ? inv.reminder_sent_at.strftime('%d.%m.%Y %H:%M') : 'не отправлено' }
      row(:created_at) { |inv| inv.created_at&.strftime('%d.%m.%Y %H.%M.%S') }
      row(:updated_at) { |inv| inv.updated_at&.strftime('%d.%m.%Y %H.%M.%S') }
    end
  end
end