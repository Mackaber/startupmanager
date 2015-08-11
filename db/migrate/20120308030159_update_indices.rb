class UpdateIndices < ActiveRecord::Migration
  def up
    remove_column "blog_posts", "hypothesis_id"
    remove_column "blog_posts", "experiment_id"
    remove_column "blog_posts", "task_id"
    
    remove_index "hypotheses", :name => "index_hypotheses_on_project_id"
    add_index "hypotheses", ["project_id", "completed_at"]
    remove_index "blog_posts", :name => "index_blog_posts_on_project_id"
    add_index "blog_posts", ["project_id", "published_at"]
  end

  def down
  end
end
