class AddOrgMemberStripeChargeId < ActiveRecord::Migration
  def up
    add_column "organization_members", "stripe_charge_id", :string
  end

  def down
  end
end
