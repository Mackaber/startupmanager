class AddMemberSort < ActiveRecord::Migration
  def up
    add_column "members", "plan_done_sort", :string, :default => "newest", :null => false
    add_column "members", "notify_goals", :boolean, :default => true, :null => false
  end

  def down
  end
end
