ActiveAdmin.register Charge do
  index do
    selectable_column
    column :organization_id
    column :amount
    column :num_members
    column :comments
    column :period_start
    column :period_end
    column :stripe_charge_id
    column :created_at
    column :updated_at
    actions
  end
end
