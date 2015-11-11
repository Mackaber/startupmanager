ActiveAdmin.register OrganizationMember do
  index do
    selectable_column
    column :user_id
    column :organization_id
    column :payment_code
    column :paid_at
    column :stripe_customer_id
    column :cc_exp_month
    column :cc_exp_year
    column :cc_last4
    column :cc_type
    column :stripe_charge_id
    column :created_at
    column :updated_at
    actions
  end
end
