class Pricing20120331 < ActiveRecord::Migration
  def up
    
    SubscriptionLevel.find_or_create_by_name("$5 Per member (3+)").destroy
    SubscriptionLevel.find_or_create_by_name("Enterprise Lite").destroy
    
    p = SubscriptionLevel.find_or_create_by_name("Personal")
    p.update_attributes!(
      :max_storage_mb => 200
    )

    SubscriptionLevel.create!(
      :name => "Garage",
      :available => true,
      :monthly_price => 9.00,
      :yearly_price => 99.00,
      :tagline => "For small teams testing multiple ideas",
      :max_projects => 3,
      :max_members => 2,
      :max_storage_mb => 1024,
      :support_chat => true
    )
    
    sl = SubscriptionLevel.find_or_create_by_name("Startup Lite")
    sl.update_attributes!(
      :max_projects => 3,
      :max_storage_mb => 10240,
      :support_chat => true
    )
    
    sp = SubscriptionLevel.find_or_create_by_name("Startup Plus")
    sp.update_attributes!(
      :monthly_price => 99.00,
      :yearly_price => 999.00,
      :max_projects => 5,
      :max_storage_mb => 25600
    )
    
    ep = SubscriptionLevel.find_or_create_by_name("Enterprise Plus")
    ep.update_attributes!(:name => "Enterprise", :available => false)
    
    unlimited = SubscriptionLevel.find_or_create_by_name("Unlimited")
    Subscription.where(:subscription_level_id => unlimited.id).update_all(:subscription_level_id => ep.id)
    unlimited.destroy
    
    remove_column "subscription_levels", "trial_days"
    remove_column "subscription_levels", "monthly_member_price"
    remove_column "subscription_levels", "free_members"
  end

  def down
  end
end
