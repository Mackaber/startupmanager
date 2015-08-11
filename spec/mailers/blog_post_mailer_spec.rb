require "spec_helper"

describe BlogPostMailer do
  before do
    @owner = Factory(:owner)
    @project = @owner.project
    @admin1 = Factory(:member_who_has_joined_project, :project => @owner.project, :role_name => 'Contributor')
    @admin2 = Factory(:member_who_has_joined_project, :project => @owner.project, :role_name => 'Contributor')
  end

  describe "blog post creation" do
    it "sends an email to all appropriate members of the project" do
      blog_post = Factory(:blog_post, :member => @owner)
      email = BlogPostMailer.mail_contents_of_blog_post(blog_post, [@admin1.user.email, @admin2.user.email].join(','))
      email.should bcc_to(@admin1.user.email, @admin2.user.email)
    end
    it "does not send mail for LeanLaunchLab project in production environment" do
      Rails.stub(:env).and_return('production')
      @project = create_lll_project
      BlogPostMailer.should_not_receive(:mail_contents_of_blog_post)
      Factory(:blog_post, :project => @project)
    end
  end

  describe "comments creation" do
    it "sends an email to all appropriate members of the project" do
      comment = Factory(:comment, :member => @owner)
      email = BlogPostMailer.mail_contents_of_comment(comment, comment.blog_post, [@admin1.user.email, @admin2.user.email].join(','))
      email.should bcc_to(@admin1.user.email, @admin2.user.email)
    end
    it "does not send mail for LeanLaunchLab project in production environment" do
      Rails.stub(:env).and_return('production')
      @project.update_attribute(:name, 'LeanLaunchLab')
      blog_post = Factory(:blog_post, :project => @project)
      BlogPostMailer.should_not_receive(:mail_contents_of_comment)
      Factory(:comment, :member => @owner, :blog_post => blog_post)
    end
  end

  describe "email digest" do
    describe "headers" do
      before do
        @email = BlogPostMailer.mail_digest(@owner.user, [@project])
      end

      it "has a from name of LeanLaunchLab and a from address of notifications@leanlaunchlab.com" do
        @email.header.fields.first.to_s.should == 'alerts@leanlaunchlab.com'
        @email.from == 'notifications@leanlaunchlab.com'
      end
      it "has a reply-to of notifications@leanlaunchlab.com" do
        @email.reply_to.should == ['support@leanlaunchlab.com']
      end
    end

    describe "body" do
      before do
        @projects = [Factory(:project, :name => "project1"), Factory(:project, :name => "project2")]
        @post_writer = Factory(:member_who_has_joined_project, :project => @projects.first)
        @post_writer2 = Factory(:member_who_has_joined_project, :project => @projects.first)
        @post1 = Factory(:blog_post, :member => @post_writer, :project => @projects.first, :subject => 'post1 subject')
        feedback1 = Factory(:comment, :blog_post => @post1, :member => @post_writer)
        feedback2 = Factory(:comment, :blog_post => @post1, :member => @post_writer2)
        @post2 = Factory(:blog_post, :member => @post_writer, :project => @projects.last, :subject => 'post2 subject')
        @email = BlogPostMailer.mail_digest(@owner.user, @projects)
      end

      it "contains the project names" do
        @email.body.should =~ /project1/
        @email.body.should =~ /project2/
      end

      it "contains the blog post subjects" do
        @email.body.should =~ /post1 subject/
        @email.body.should =~ /post2 subject/
      end

      it "contains links to the new blog posts" do
        @email.body.should =~ /#{projects_blog_post_path(@projects.first.id, @post1.id)}/
        @email.body.should =~ /#{projects_blog_post_path(@projects.last.id, @post2.id)}/
      end

      it "contains new feedback authors names" do
        pending "no longer a feature"
        @email.body.should =~ /#{@post_writer.user.name}/
        @email.body.should =~ /#{@post_writer2.user.name}/
      end

      describe "subject" do
        it "has the right subject" do
          @email.subject.should == "#{@owner.user.name.split(' ').first}, Team project1 and 1 other project have new updates"
        end
      end
    end
  end

  describe "digest_subject method" do
    before(:all) do
      @p1 = Factory(:project)
      @p2 = Factory(:project)
      @p3 = Factory(:project)
    end
    it 'has the right text for one updated project' do
      pending "doesn't seem like you can test a method in a mailer like this"
      BlogPostMailer.digest_subject(@owner.user, [@p1]).should == "#{@owner.user.name}, Team #{@p1.name} has new updates"
    end
    it 'has the right text for two updated projects'do
      pending "doesn't seem like you can test a method in a mailer like this"
      BlogPostMailer.digest_subject(@owner.user, [@p1, @p2]).should == "#{@owner.user.name}, Team #{@p1.name} and 1 other project have new updates"
    end
    it 'has the right text for three updated project'do
      pending "doesn't seem like you can test a method in a mailer like this"
      BlogPostMailer.digest_subject(@owner.user, [@p1, @p2, @p3]).should == "#{@owner.user.name}, Team #{@p1.name} and 2 other projects have new updates"
    end
  end
end
