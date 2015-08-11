class AddProjectGoals < ActiveRecord::Migration
  def up
    add_column "projects", "goal_canvas_completed", :boolean, :default => false, :null => false
    add_column "projects", "goal_create_hypothesis_completed", :boolean, :default => false, :null => false
    add_column "projects", "goal_test_hypothesis_completed", :boolean, :default => false, :null => false
    add_column "projects", "goal_validate_hypothesis_completed", :boolean, :default => false, :null => false
    add_column "projects", "goal_interview_completed", :boolean, :default => false, :null => false
    add_column "projects", "goal_invite_completed", :boolean, :default => false, :null => false
    Project.reset_column_information
    
    Project.find_each do |project|
      project.goal_canvas_completed = (project.canvas_items.count > 0)
      project.goal_create_hypothesis_completed = (project.hypotheses.non_canvas.count > 0)
      project.goal_test_hypothesis_completed = (project.hypotheses.where("item_status_id IS NOT NULL").count > 0)
      project.goal_validate_hypothesis_completed = (project.hypotheses.where(["item_status_id IN (?)", [ItemStatus.cached_find_by_status("valid").id, ItemStatus.cached_find_by_status("invalid").id, ItemStatus.cached_find_by_status("unknown").id]]).count > 0)
      project.goal_interview_completed = (project.blog_posts.interviews.count > 0)
      project.goal_invite_completed = (project.members.count > 1)
      project.save(:validate => false)
    end
  end

  def down
  end
end
