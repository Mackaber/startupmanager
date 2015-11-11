ActiveAdmin.register Organization do
  index do
    selectable_column
    column :name
    column :organization_type
    column :stripe_customer_id
    # column :cc_exp_month
    # column :cc_exp_year
    # column :cc_last4
    # column :cc_type
    # column :cc_user_id
    column :brightidea_api_key
    column :trial_end_date
    column :invoice_billing
    column :auto_locked
    column :admin_locked
    column :promotion_id
    column :promotion_expires_at
    column :member_price
    column :created_at
    column :updated_at
    actions
  end
end
