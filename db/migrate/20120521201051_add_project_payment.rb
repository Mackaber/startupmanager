class AddProjectPayment < ActiveRecord::Migration
  def up
    add_column "projects", "stripe_customer_id", :string
    add_column "projects", "cc_exp_month", :integer
    add_column "projects", "cc_exp_year", :integer
    add_column "projects", "cc_last4", :string
    add_column "projects", "cc_type", :string
    add_column "projects", "cc_user_id", :integer
    add_column "projects", "price", :decimal, :precision => 10, :scale => 2
    add_column "projects", "payment_code", :string
    add_index "projects", "payment_code", :unique => true
    add_column "projects", "paid_at", :date
  end

  def down
  end
end
