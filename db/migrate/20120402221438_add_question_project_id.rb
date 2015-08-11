class AddQuestionProjectId < ActiveRecord::Migration
  def up
    add_column "questions", "project_id", :integer
    add_index "questions", "project_id"
    add_foreign_key "questions", "projects", :dependent => :delete
    Question.reset_column_information
    
    Question.find_each do |question|
      question.project = question.hypothesis.project
      question.save(:validate => false)
    end
    
    change_column_null "questions", "project_id", false
  end

  def down
  end
end
