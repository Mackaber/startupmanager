class AddUserGoalNotified < ActiveRecord::Migration
  def up
    add_column "settings", "project_goal_canvas_notified_at", :datetime
    add_column "settings", "project_goal_hypothesis_notified_at", :datetime
    add_column "settings", "project_goal_test_notified_at", :datetime
    add_column "settings", "project_goal_validate_notified_at", :datetime
    add_column "settings", "project_goal_interview_notified_at", :datetime
    add_column "settings", "project_goal_invite_notified_at", :datetime
  end

  def down
  end
end
