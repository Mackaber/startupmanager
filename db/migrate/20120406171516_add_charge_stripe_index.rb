class AddChargeStripeIndex < ActiveRecord::Migration
  def up
    add_index "charges", "stripe_charge_id"
    add_index "organizations", "stripe_customer_id", :unique => true
  end

  def down
  end
end
