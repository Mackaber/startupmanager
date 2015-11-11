ActiveAdmin.register SubscriptionLevel do
  index do
    selectable_column
    column :name
    column :tagline
    column :description
    column :available
    column :monthly_price
    column :yearly_price
    column :max_projects
    column :max_members
    column :max_storage_mb
    column :support_email
    column :support_chat
    column :support_phone
    column :created_at
    column :updated_at
    actions
  end
end
