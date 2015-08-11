require "spec_helper"

describe BlogPostsHelper do
  before do
    @owner = Factory(:owner)
    @project = @owner.project
    @member = Factory(:member, :project => @project, :level => "Normal")
    @blog_post = Factory(:blog_post, :member => @member)
  end

  describe "comments to display" do
    it 'should return the comments for the blog post' do
      Factory(:comment, :blog_post => @blog_post, :member => @owner)
      helper.comments_to_display(@blog_post).count.should == 1
    end
    it 'should not include nothing to add comments' do
      Factory(:comment, :blog_post => @blog_post, :member => @owner)
      Factory(:comment, :blog_post => @blog_post, :member => @owner, :nothing_to_add => true)
      helper.comments_to_display(@blog_post).count.should == 1
    end
  end


  describe "describe_unread" do
    it "returns a string containing comment author name and number of comments" do
      (1..5).each do |number|
        member = Factory(:member, :project => @project, :level => "Normal")
        member.user.update_attribute(:name, "user#{number}")
        number.times do
          Factory(:comment, :blog_post => @blog_post, :member => member)
        end
      end
      helper.describe_unread(@blog_post.unread_comments(@owner)).should == 'user1(1), user2(2), user3(3), user4(4), user5(5)'
    end
  end

  # TODO:  pretty sure these are going away ... delete them if that's true (says Kai, Oct 2)
  #describe "comments form labels" do
  #  describe "feedback_textarea_label" do
  #    context "member has Normal permission level" do
  #      it 'should return the text' do
  #        member = Factory(:member, :project => @project, :level => "Normal")
  #        helper.feedback_textarea_label(member).should == "Enter Response..."
  #      end
  #    end
  #  end
  #
  #  describe "feedback_button_label" do
  #    context "member has Normal permission level" do
  #      it 'should return the text' do
  #        member = Factory(:member, :project => @project, :level => "Normal")
  #        helper.feedback_button_label(member).should == "Send Response"
  #      end
  #    end
  #  end
  #end


end
