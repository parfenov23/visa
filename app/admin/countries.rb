ActiveAdmin.register Country do
  permit_params :code, :title, :title_ru, :flag, :position

  config.sort_order = 'position_asc'

  filter :code
  filter :title
  filter :title_ru

  index do
    selectable_column
    id_column
    column :position
    column :flag
    column :code
    column :title
    column :title_ru
    actions
  end

  form do |f|
    f.semantic_errors

    f.inputs 'Country' do
      f.input :code, hint: 'ISO-like 3-letter code, e.g. RUS'
      f.input :title, label: 'Title (EN)'
      f.input :title_ru, label: 'Title (RU)'
      f.input :flag, hint: 'Emoji flag, e.g. 🇷🇺'
      f.input :position
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :position
      row :code
      row :title
      row :title_ru
      row :flag
      row :created_at
      row :updated_at
    end
  end
end