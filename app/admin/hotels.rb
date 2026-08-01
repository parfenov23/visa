ActiveAdmin.register Hotel do
  menu label: "Hotels (база)", priority: 3

  permit_params :name, :name_ru, :city, :address, :address_ru, :phone

  filter :name
  filter :name_ru
  filter :city
  filter :phone

  index do
    selectable_column
    id_column
    column :name
    column :name_ru
    column :city
    column :address
    column :address_ru
    column :phone
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs "Hotel" do
      f.input :name,       label: "Название (EN)"
      f.input :name_ru,    label: "Название (RU)"
      f.input :city,       label: "Город"
      f.input :address,    label: "Адрес (EN)", hint: "Напр.: st. Godovikova, 7A, Moscow, 129085"
      f.input :address_ru, label: "Адрес (RU)", hint: "Напр.: ул. Годовикова, 7А, Москва, 129085"
      f.input :phone,      label: "Телефон",    hint: "Напр.: +7 905 715 07 23"
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :name_ru
      row :city
      row :address
      row :address_ru
      row :phone
      row('Подстановка (EN)') { |h| h.full_en }
      row('Подстановка (RU)') { |h| h.full_ru }
      row :created_at
      row :updated_at
    end
  end
end
