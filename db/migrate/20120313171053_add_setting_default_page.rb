class AddSettingDefaultPage < ActiveRecord::Migration
  def up
    add_column "settings", "home_page", :string
  end

  def down
  end
end
