require 'spec_helper'

describe MemberBlogPostView do
  it 'updates existing record for same blog post and member' do
    owner = Factory(:owner)
    blog_post = Factory(:blog_post, :member => owner)

    first_create = MemberBlogPostView.create(:member => owner, :blog_post => blog_post)
    second_create = MemberBlogPostView.create(:member => owner, :blog_post => blog_post)

    first_create.should == second_create
    MemberBlogPostView.count.should == 1
  end
end
