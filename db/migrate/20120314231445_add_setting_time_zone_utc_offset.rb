class AddSettingTimeZoneUtcOffset < ActiveRecord::Migration
  def up    
    Setting.without_auditing do
      User.without_auditing do
        Setting.find_each do |setting|
          setting.time_zone = ActiveSupport::TimeZone.new(setting.time_zone).tzinfo.name
          setting.save!
        end
      end
    end
    add_index "settings", "user_id"
    add_index "settings", "time_zone"
    change_column_default "settings", "time_zone", "America/Los_Angeles"
  end

  def down
  end
end
