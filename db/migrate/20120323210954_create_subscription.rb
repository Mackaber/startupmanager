class CreateSubscription < ActiveRecord::Migration
  def up
    Organization.where(:invoice_billing => true).where(:custom_yearly_price => 0).update_all(:invoice_billing => false)
    Organization.where(:custom_yearly_price => 0).where(:subscription_yearly => false).update_all(:subscription_yearly => true)
    
    create_table "subscriptions" do |t|
      t.integer "organization_id", :null => false
      t.integer "subscription_level_id", :null => false
      t.boolean "yearly", :default => false, :null => false
      t.decimal  "price",     :precision => 10, :scale => 2, :null => false
      t.date "start_date", :null => false
      t.date "end_date"
      t.timestamps
    end
    add_index "subscriptions", "organization_id"
    add_index "subscriptions", "subscription_level_id"
    add_foreign_key "subscriptions", "organizations", :dependent => :delete
    add_foreign_key "subscriptions", "subscription_levels"
    
    Subscription.reset_column_information
    
    Organization.belongs_to :subscription_level    
    Organization.where("subscription_level_id IS NOT NULL").find_each do |organization|
      price = organization.subscription_yearly ? (organization.custom_yearly_price || organization.subscription_level.yearly_price) : (organization.custom_monthly_price || organization.subscription_level.monthly_price)
      organization.subscriptions.create!(
        :subscription_level => organization.subscription_level,
        :yearly => organization.subscription_yearly,
        :price => price,
        :start_date => organization.subscription_start_date || (organization.trial_end_date + 1),
        :end_date => (organization.custom_monthly_price && organization.custom_monthly_price < 100) ? Date.parse("2012-06-30") : nil
      )
    end
    
    remove_column "organizations", "custom_yearly_price"
    remove_column "organizations", "custom_monthly_price"
    remove_column "organizations", "subscription_start_date"
    remove_column "organizations", "subscription_end_date"
    remove_column "organizations", "subscription_level_id"
    remove_column "organizations", "subscription_yearly"    
  end

  def down
  end
end
