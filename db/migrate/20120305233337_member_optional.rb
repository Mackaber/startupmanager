class MemberOptional < ActiveRecord::Migration
  def up
    remove_foreign_key "blog_posts", :name => "blog_posts_member_id_fk"
    add_foreign_key "blog_posts", "members"
    remove_foreign_key "comments", :name => "comments_member_id_fk"
    add_foreign_key "comments", "members"
  end

  def down
  end
end
