ActiveAdmin.register Subscription do
  index do
    selectable_column
    column :organization_id
    column :subscription_level_id
    column :yearly
    column :price
    column :start_date
    column :end_date
    column :created_at
    column :updated_at
    actions
  end
end
