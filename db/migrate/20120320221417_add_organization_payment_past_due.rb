class AddOrganizationPaymentPastDue < ActiveRecord::Migration
  def up
    add_column "organizations", "auto_locked", :boolean, :default => false, :null => false
    add_column "organizations", "admin_locked", :boolean, :default => false, :null => false
    add_column "organizations", "admin_comments", :text
  end

  def down
  end
end
