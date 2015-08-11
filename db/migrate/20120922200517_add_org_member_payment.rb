class AddOrgMemberPayment < ActiveRecord::Migration
  def up
    add_column "organizations", "member_price", :decimal, :precision => 10, :scale => 2
    add_column "organization_members", "payment_code", :string
    add_column "organization_members", "paid_at", :date
    add_column "organization_members", "stripe_customer_id", :string
    add_column "organization_members", "cc_exp_month", :integer
    add_column "organization_members", "cc_exp_year", :integer
    add_column "organization_members", "cc_last4", :string
    add_column "organization_members", "cc_type", :string    
  end

  def down
  end
end
