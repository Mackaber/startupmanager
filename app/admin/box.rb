ActiveAdmin.register Box do
  index do
    selectable_column
    column :name
    column :label
    column :description
    column :startup_label
    column :startup_description
    actions
  end
end
