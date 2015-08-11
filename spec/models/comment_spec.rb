require 'spec_helper'

describe Comment do
  describe 'validations' do
    it "is valid" do
      owner = Factory(:owner)
      blog_post = Factory(:blog_post, :member => owner)

      comment = Comment.new(:blog_post => blog_post, :member => owner, :body => "comment contents")
      comment.should be_valid
    end

    it "factory is valid" do
      Factory.build(:comment).should be_valid
    end

    [:member].each do |att|
      it "is not valid without #{att}" do
        subject.should_not be_valid
        subject.errors[att].should_not be_empty
      end
    end
    
    [:blog_post].each do |att|
      it "is not valid without #{att}" do
        pending "comment requires either blog_post, experiment, task, or hypothesis"
        subject.should_not be_valid
        subject.errors[att].should_not be_empty
      end
    end
    

    it "is not valid without body if nothing_to_add is false" do
      Factory.build(:comment, :body => '', :nothing_to_add => false).should_not be_valid
    end

    it "is valid without body if nothing_to_add is true" do
      Factory.build(:comment, :body => '', :nothing_to_add => true).should be_valid
    end
  end

  describe "#mail_to" do
    before do
      @owner = Factory(:owner)
      @comment = Factory(:comment, :member => @owner)
    end

    it "is empty if the only member on the project is the owner" do
      some_dude_on_another_project = Factory(:member_who_has_joined_project)
      @comment.mail_to.should == ""
    end

    it "is empty if the only other member is deactivated" do
      deactivated_member = Factory(:member_who_has_joined_project, :project => @owner.project)
      deactivated_member.update_attribute(:activated, false)
      @comment.mail_to.should == ""
    end

    it "does not include members who have feedback_email preference set to false" do
      no_mail_member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Admin")
      wants_mail_member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Admin")
      no_mail_member.user.setting.update_attribute(:feedback_email, false)
      @comment.member.project.reload # TODO: somehow this is necessary, otherwise only @owner is in .members
      @comment.mail_to.should include(wants_mail_member.user.email)
      @comment.mail_to.should_not include(no_mail_member.user.email)
    end

    it "is empty if the only other member hasn't joined the project" do
      non_joined_member = Factory(:member, :project => @owner.project)
      @comment.mail_to.should == ""
    end

    it "is empty if the only other member is a Viewer" do
      viewer = Factory(:member_who_has_joined_project, :project => @owner.project)
      @comment.mail_to.should == ""
    end

    it "is a single email address if there is exactly one other member on the project" do
      admin = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Admin")
      @comment.member.project.reload # TODO: somehow this is necessary, otherwise only @owner is in .members
      @comment.mail_to.should == admin.user.email
    end

    it "is a comma-separated string of several email addresses if there are other members on the project" do
      admin = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Admin")
      normal = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Normal")
      @comment.member.project.reload # TODO: somehow this is necessary, otherwise only @owner is in .members
      mail_to = @comment.mail_to
      mail_to.should match /#{admin.user.email}/
      mail_to.should match /#{normal.user.email}/
      mail_to.split(',').count.should == 2
    end
  end

  describe "creation" do
    it 'happy path: it sends email' do
      message = double
      message.should_receive(:deliver)
      BlogPostMailer.should_receive(:mail_contents_of_comment).and_return(message)
      owner = Factory(:owner)
      Factory(:member_who_has_joined_project, :project => owner.project, :level => 'Admin')
      blog_post = Factory(:blog_post, :member => owner)
      Comment.create(:member => owner, :blog_post => blog_post, :body => "some body content")
    end

    context "nothing to add" do
      before do
        BlogPostMailer.should_not_receive(:mail_contents_of_comment)
        @owner = Factory(:owner)
        Factory(:member_who_has_joined_project, :project => @owner.project, :level => 'Admin')
        @blog_post = Factory(:blog_post, :member => @owner)
      end

      it 'should not send mail if nothing_to_add is true' do
        Factory(:comment, :blog_post => @blog_post, :nothing_to_add => true)
      end
    end

    context "zero recipients" do
      before do
        BlogPostMailer.should_not_receive(:mail_contents_of_comment)
        @owner = Factory(:owner)
        @blog_post = Factory(:blog_post, :member => @owner)
      end

      it 'should not attempt to send email if commenter is the only member' do
        Comment.create(:member => @owner, :blog_post => @blog_post, :body => "This is a comment.")
      end

      it 'should not attempt to send email if commenter is the only _joined_ member' do
        Factory(:member, :project => @owner.project, :join_code => 'not joined')
        Comment.create(:member => @owner, :blog_post => @blog_post, :body => "Oops, I have nobody to send to!")
      end

      it 'should not attempt to send email if commenter is the only _activated_ member' do
        other_member = Factory(:member_who_has_joined_project, :project => @owner.project)
        other_member.update_attribute(:activated, false)
        Comment.create(:member => @owner, :blog_post => @blog_post, :body => "Oops, I have nobody to send to!")
      end

      it 'should not attempt to send email if commenter is the only non-viewer member' do
        Factory(:member_who_has_joined_project, :project => @owner.project, :level => 'Viewer')
        Comment.create(:member => @owner, :blog_post => @blog_post, :body => "Oops, I have nobody to send to!")
      end
    end
  end
end
