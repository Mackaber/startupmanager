ActiveAdmin.register Project do
  index do
    selectable_column
    column :stripe_customer_id
    column :cc_exp_month
    column :cc_exp_year
    column :cc_last4
    column :cc_type
    column :cc_user_id
    column :cc_user do |resource|
      resource.cc_user.try(:name)
    end
    column :price
    column :payment_code
    column :paid_at
    actions
  end
end
