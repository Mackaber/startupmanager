class PlanTweak120305 < ActiveRecord::Migration
  def up
    p = SubscriptionLevel.find_or_create_by_name("Personal")
    p.update_attributes!(:tagline => "For individuals")
    
    p = SubscriptionLevel.find_or_create_by_name("Startup Plus")
    p.update_attributes!(:max_projects => 1, :max_storage_mb => 2048)
    
    p = SubscriptionLevel.find_or_create_by_name("Enterprise Lite")
    p.update_attributes!(:max_projects => 3, :support_phone => false, :max_storage_mb => 25600)

    p = SubscriptionLevel.find_or_create_by_name("Enterprise Plus")
    p.update_attributes!(:max_storage_mb => 51200)
  end

  def down
  end
end
