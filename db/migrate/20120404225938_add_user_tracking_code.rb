class AddUserTrackingCode < ActiveRecord::Migration
  def up
    add_column "users", "tracking_code", :string
    User.reset_column_information
    
    User.without_auditing do
      User.find_each do |user|
        user.tracking_code = User.random_tracking_code
        user.save!
      end
    end
    change_column_null "users", "tracking_code", false
    
    add_index "users", "tracking_code", :unique => true
  end

  def down
  end
end
