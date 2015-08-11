class MemberBlogPostView < ActiveRecord::Base
  belongs_to :member
  belongs_to :blog_post, :touch => true

  def self.create(attrs)
    existing = MemberBlogPostView.where(:member_id => attrs[:member].id, :blog_post_id => attrs[:blog_post].id).first
    if existing
      return existing.update_attributes(:member_id => attrs[:member].id, :blog_post_id => attrs[:blog_post].id)
    else
      return super.class.create(attrs)
    end
  end
end
