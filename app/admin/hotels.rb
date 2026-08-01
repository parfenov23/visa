ActiveAdmin.register Hotel do
  menu label: "Hotels (база)", priority: 3

  permit_params :name, :name_ru, :city, :address

  filter :name
  filter :name_ru
  filter :city

  index do
    selectable_column
    id_column
    column :name
    column :name_ru
    column :city
    column :address
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs "Hotel" do
      f.input :name,    label: "Название (EN)"
      f.input :name_ru, label: "Название (RU)"
      f.input :city,    label: "Город"
      f.input :address, label: "Адрес"
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :name_ru
      row :city
      row :address
      row :created_at
      row :updated_at
    end
  end
end
