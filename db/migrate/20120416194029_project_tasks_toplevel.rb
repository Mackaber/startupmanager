class ProjectTasksToplevel < ActiveRecord::Migration
  def up
    change_column_null "tasks", "hypothesis_id", true
    remove_foreign_key "tasks", :name => "goals_item_status_id_fk"
    remove_column "tasks", "item_status_id"
    add_column "tasks", "description", :text
    
    ProjectTask.update_all("position = null", "completed_at is not null")
    Project.find_each do |project|
      project.tasks.where("completed_at is null").order("position ASC").each_with_index{|x,i| x.update_attributes!(:position => i+1)}
    end
  end

  def down
  end
end
