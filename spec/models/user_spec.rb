require 'spec_helper'

describe User do
  describe "associations" do
    it "has members" do
      subject.should respond_to :members
    end
    it "has projects" do
      subject.should respond_to :projects
    end
    it "has settings" do
      subject.should respond_to :setting
    end
    it "has blog_posts" do
      subject.should respond_to :blog_posts
    end
  end

  describe "creation" do
    it "creates associated setting obj" do
      user = Factory(:user)
      user.reload.setting.should_not be_nil
    end
  end

  describe "#new_posts_and_comments" do
    before do
      @now = Time.now.utc
      @user = Factory(:confirmed_user)
      @project = Factory(:project)
      @post_author = Factory(:member_who_has_joined_project, :project => @project)
      @member = Factory(:member_who_has_joined_project, :user => @user, :project => @project)
    end

    context "user has less than 10 activities" do
      it "returns nothing" do
        @user.new_posts_and_comments.should be_empty
      end
    end

    context "user has more than 9 activities" do
      before { 10.times { |i| Factory(:user_activity, :created_at => @now - i.seconds, :user_id => @user.id) } }

      context "user was active just over 12 hours ago" do
        before { Factory(:user_activity, :user_id => @user.id, :created_at => @now - 13.hours) }

        context "there were no new posts or comments in the last 12 hours" do
          before do
            @post = Factory(:blog_post, :member => @post_author, :published_at => @now - 1.week)
            Factory(:comment, :blog_post => @post, :created_at => @now - 2.days)
          end

          it "returns nothing" do
            @user.new_posts_and_comments.should be_empty
          end
        end

        context "there were new posts in the last 12 hours (but no new comments)" do
          before { @post = Factory(:blog_post, :member => @post_author, :published_at => @now - 11.hours) }

          it 'returns the posts in the last 12 hours' do
            @user.new_posts_and_comments.first.should == @post
          end
        end

        context "there were new comments in the last 12 hours (but no new posts)" do
          before do
            @post = Factory(:blog_post, :member => @post_author, :published_at => @now - 1.week)
            Factory(:comment, :blog_post => @post, :created_at => @now - 11.hours)
          end

          it "returns the posts with new comments in the last 12 hours" do
            @user.new_posts_and_comments.first.should == @post
          end
        end

        context "the jumbo case - lots of recent posts/comments" do
          before do
            @non_relevant_post = Factory(:blog_post, :member => @post_author, :published_at => @now - 2.week)
            @old_post = Factory(:blog_post, :member => @post_author, :published_at => @now - 1.week)
            Factory(:comment, :blog_post => @old_post, :created_at => @now - 11.hours)
            @new_post = Factory(:blog_post, :member => @post_author, :published_at => @now - 11.hours)
            @user_post = Factory(:blog_post, :member => @post_author, :published_at => @now - 10.hours)
          end

          it "returns the 3 posts in the last 12 hours" do
            resultset = @user.new_posts_and_comments
            resultset.should_not include @non_relevant_post
            resultset.should include @old_post
            resultset.should include @new_post
            resultset.should include @user_post
          end

          it "sorts the posts by date descending" do
            @user.new_posts_and_comments.first.should == @user_post
            @user.new_posts_and_comments.last.should == @old_post
          end

          it "does not return a post multiple times if it has multiple new comments" do
            3.times { |i| Factory(:comment, :blog_post => @new_post, :created_at => @now - (i + 1).hours) }
            @user.new_posts_and_comments.count.should == 3
          end
        end
      end
    end
  end

  describe "#comments_to_highlight" do
    before do
      @now = Time.now.utc
      @user = Factory(:confirmed_user)
      @project = Factory(:project)
      @post_author = Factory(:member_who_has_joined_project, :project => @project)
      @member = Factory(:member_who_has_joined_project, :user => @user, :project => @project)
    end

    context "without new comments" do
      it "returns empty" do
        @user.comments_to_highlight(@user.new_posts_and_comments).should be_empty
      end
    end

    context "with new comments" do
      before do
        @old_post = Factory(:blog_post, :member => @post_author, :published_at => Time.now - 2.weeks)
        @new_comment = Factory(:comment, :blog_post => @old_post, :created_at => Time.now.utc - 2.hours)
      end

      it "returns comment ids for comments with created_at newer than last activity" do
        @user.comments_to_highlight(@user.new_posts_and_comments).should == [@new_comment.id]
      end
    end
  end

  describe "#posts_to_highlight" do
    before do
      @now = Time.now.utc
      @user = Factory(:confirmed_user)
      @project = Factory(:project)
      @post_author = Factory(:member_who_has_joined_project, :project => @project)
      @member = Factory(:member_who_has_joined_project, :user => @user, :project => @project)
    end

    context "without new posts" do
      it "returns empty" do
        @user.posts_to_highlight(@user.new_posts_and_comments).should be_empty
      end
    end

    context "with new posts" do
      before do
        @new_post = Factory(:blog_post, :member => @post_author, :published_at => Time.now - 2.hours)
      end

      it "returns post ids for posts with a created_at newer than last activity" do
        @user.posts_to_highlight(@user.new_posts_and_comments).should == [@new_post.id]
      end
    end
  end

  describe "#last_activity_12hours_out" do
    before { @user = Factory(:confirmed_user) }
    context "brand new user (has less than 10 activities)" do
      it "returns the ~ current time in utc - 12 hours" do
        twelve_ago = Time.now.utc - 12.hours
        @user.last_activity_12hours_out.hour.should == twelve_ago.hour
        @user.last_activity_12hours_out.min.should == twelve_ago.min
      end
    end
    context "returning user" do
      before do
        now = Time.now
        @activities = (0..11).map { |i| Factory(:user_activity, :created_at => now - (i * 5).hours, :user => @user) }
      end
      it "returns a time for the first activity more than 12 hours out" do
        @user.last_activity_12hours_out.should == @activities[3].created_at
      end
    end
  end

  describe "#live_projects" do
    before { @user = Factory(:confirmed_user) }

    pending "no confirmation" do
      it "does not return unjoined projects" do
        Factory(:member, :project => Factory(:project), :user => @user)
        @user.live_projects.count.should be_zero
      end
    end

    it "does not return inactive projects" do
      member = Factory(:member_who_has_joined_project, :project => Factory(:project), :user => @user)
      member.update_attribute(:activated, false)
      @user.live_projects.count.should be_zero
    end

    it "returns an array of projects in alphabetical order by name" do
      %w(c B a D e).each do |name|
        project = Factory(:project, :name => name)
        Factory(:member_who_has_joined_project, :project => project, :user => @user)
      end
      @user.live_projects.map(&:name).should == ['a', 'B', 'c', 'D', 'e']
    end
  end

  describe '#editable_projects' do
    before do
      #TODO add testing for permission level of "Normal"
      @user = Factory(:confirmed_user)
      @p1 = Factory(:project)
      @p2 = Factory(:project)
      user_p1_viewer = Factory(:member_who_has_joined_project, :project => @p1, :user => @user, :level => 'Viewer')
      writer_p1 = Factory(:member_who_has_joined_project, :project => @p1, :level => 'Admin')
      user_p2_admin = Factory(:member_who_has_joined_project, :project => @p2, :user => @user, :level => 'Admin')
      writer_p2 = Factory(:member_who_has_joined_project, :project => @p2, :level => 'Admin')
      Factory(:blog_post, :member_id => writer_p1.id)
      Factory(:blog_post, :member_id => writer_p2.id)
    end

    it "does not include project where @user has a viewer permission level" do
      @user.projects_user_can_edit_blogposts.should_not include(@p1.id)
    end

    it "includes project where @user has an admin permission level" do
      @user.projects_user_can_edit_blogposts.should include(@p2.id)
    end
  end

  describe "#all_members_from_all_projects" do
    before do
      @owner = Factory(:owner)
      @user = @owner.user
      @project = @owner.project
      Project.find_by_name("LeanLaunchLab").should be_nil
    end

    context "one project" do
      context "just one user - 'self', the owner" do
        it "is empty" do
          @user.all_members_from_all_projects.should be_empty
        end
      end

      context "another provisional user is on the project" do
        pending "no confirmation" do
          it "doesn't include non-joined members" do
            Factory(:member_with_confirmed_user, :project => @project)
            @user.all_members_from_all_projects.should be_empty
          end
        end
        it "doesn't include deactivated members" do
          Factory(:member_who_has_joined_project, :project => @project).deactivate
          @user.all_members_from_all_projects.should be_empty
        end
      end

      context "another user has joined the project" do
        before do
          @viewer = Factory(:member_who_has_joined_project, :project => @project, :level => "Viewer")
        end

        it "lists just that one user" do
          @user.all_members_from_all_projects.to_a.should == [@viewer]
        end
      end

      context "two other users have joined the project" do
        before do
          @newer = Factory(:member_who_has_joined_project, :project => @project, :created_at => Time.now - 1.years)
          @older = Factory(:member_who_has_joined_project, :project => @project, :created_at => Time.now - 2.years)
        end

        it "lists the two users in order of most recently joined first" do
          @user.all_members_from_all_projects.to_a.should == [@newer, @older]
        end
      end
    end

    context "with the LeanLaunchLab project" do
      before do
        lll_project = create_lll_project
        join_the_lll_project @user
      end

      context "plus one project" do
        it "is empty" do
          @user.all_members_from_all_projects.should be_empty
        end
      end

      context "plus two projects" do
        before do
          @owner2 = Factory(:owner)
          @second_membership = Factory(:member, :project => @owner2.project, :user => @user)
        end

        pending "no confirmation" do
          context "but user hasn't accepted invitation to the second project" do
            it "is empty" do
              @user.all_members_from_all_projects.should be_empty
            end
          end
        end
        
        context "but user has been deactivated on the second project" do
          before do
            @second_membership.update_attributes(:join_code => nil, :activated => false)
          end
          it "is empty" do
            @user.all_members_from_all_projects.should be_empty
          end
        end

        context "user is fully joined and active on the second project" do
          before do
            @second_membership.update_attribute(:join_code, nil)
          end
          it "lists only the other member (the owner) of that second project" do
            @user.all_members_from_all_projects.to_a.should == [@owner2]
          end
        end
      end

    end
  end

  describe "#projects_with_new_posts_or_feedback" do
    before do
      @owner = Factory(:owner)
      @user = @owner.user
    end

    describe "No new posts or feedback" do
      it "returns an empty enumerable" do
        @user.projects_with_new_posts_or_feedback.should be_empty
      end
    end

    describe "New posts and/or feedback exist" do
      before do
        @project1 = @owner.project
        @post_writer1 = Factory(:member_who_has_joined_project, :project => @project1)
        @owner2 = Factory(:owner, :user => @user)
        @project2 = @owner2.project
        @post_writer2 = Factory(:member_who_has_joined_project, :project => @project2)
        Factory(:project)
      end
      it "returns an enumerable of projects with posts in the last 24 hours" do
        Factory(:blog_post, :project => @project1, :member => @post_writer1)
        Factory(:blog_post, :project => @project2, :member => @post_writer2)
        @user.projects_with_new_posts_or_feedback.should include(@project1)
        @user.projects_with_new_posts_or_feedback.should include(@project2)
        @user.projects_with_new_posts_or_feedback.length.should == 2
      end

      it "returns an enumerable of projects with feedback in the last 24 hours" do
        old_post = Factory(:blog_post, :project => @project1, :member => @post_writer1, :published_at => Time.now - 1.week)
        Factory(:comment, :blog_post => old_post, :created_at => Time.now)
        @user.projects_with_new_posts_or_feedback.length.should == 1
      end
      it "does not return projects that only have posts older than 24 hours ago" do
        old_post = Factory(:blog_post, :project => @project1, :member => @post_writer1, :published_at => Time.now - 25.hours)
        @user.projects_with_new_posts_or_feedback.length.should == 0
      end
      it "does not return projects that only have posts within the last 24 hours that were made by the user" do
        new_post_by_user = Factory(:blog_post, :project => @project1, :member => @owner)
        @user.projects_with_new_posts_or_feedback.length.should == 0
      end
      it "does not return projects that only have feedback older than 24 hours ago" do
        old_post = Factory(:blog_post, :project => @project1, :member => @post_writer1, :published_at => Time.now - 1.week)
        Factory(:comment, :blog_post => old_post, :created_at => Time.now - 25.hours)
        @user.projects_with_new_posts_or_feedback.length.should == 0
      end
      it "does not return projects that only have feedback within the last 24 hours that were made by the user" do
        old_post = Factory(:blog_post, :project => @project1, :member => @post_writer1, :published_at => Time.now - 1.week)
        Factory(:comment, :blog_post => old_post, :created_at => Time.now, :member => @owner)
        @user.projects_with_new_posts_or_feedback.length.should == 0
      end
    end

    describe "sorting" do
      it "lists projects with the same number of new posts in alphabetical order" do
        project_names = %w(charlie beta alpha)
        project_names.each do |name|
          project = Factory(:project, :name => name)
          Factory(:owner, :project => project, :user => @user)
          post_writer = Factory(:member_who_has_joined_project, :project => project)
          Factory(:blog_post, :member => post_writer, :published_at => Time.now)
        end
        projects = @user.projects_with_new_posts_or_feedback
        projects.map(&:name).should == project_names.sort
      end

      it "lists projects with more new posts before projects with fewer new posts" do
        pending "decided to put off implementing this"
        project_names = %w(delta charlie beta alpha)
        blog_post_counts = [1, 3, 2, 4]
        project_names.each_with_index do |name, index|
          project = Factory(:project, :name => name)
          Factory(:owner, :project => project, :user => @user)
          post_writer = Factory(:member_who_has_joined_project, :project => project)
          blog_post_counts[index].times { Factory(:blog_post, :member => post_writer, :published_at => Time.now) }
        end
        projects = @user.projects_with_new_posts_or_feedback
        projects.map(&:name).should == %w(alpha charlie beta delta)
      end

      it "lists projects with new posts before projects with new feedback" do
        pending "decided to put off implementing this"
        project_names = %w(delta charlie beta alpha)
        blog_post_counts = [1, 0, 2, 0]
        feedback_counts = [0, 3, 0, 1]
        project_names.each_with_index do |name, index|
          project = Factory(:project, :name => name)
          Factory(:owner, :project => project, :user => @user)
          post_writer = Factory(:member_who_has_joined_project, :project => project)
          blog_post_counts[index].times do
            puts "creating post on #{name}"
#            Factory(:blog_post, :member => post_writer, :published_at => Time.now)
            puts Factory(:blog_post, :member => post_writer, :published_at => Time.now).inspect
          end
          feedback_counts[index].times do
            old_post = Factory(:blog_post, :member => post_writer, :published_at => Time.now - 1.week)
            Factory(:comment, :blog_post => old_post, :published_at => Time.now)
          end
        end
        projects = @user.projects_with_new_posts_or_feedback
        projects.map(&:name).should == %w(beta delta charlie alpha)
      end
    end
  end

  describe "#is_admin? -- project authority" do
    before do
      owner = Factory(:owner)
      @user = owner.user
      @project = owner.project
    end
    it "- user knows he is an admin of a project he is an owner of" do
      @user.should be_is_admin(@project)
    end
    it "- user knows he is an admin of a project he is an admin of" do
      member2 = Factory(:member_who_has_joined_project, :project => @project, :level => "Admin")
      user2 = member2.user
      user2.should be_is_admin(@project)
    end
    it "returns false when user is deactivated" do
      member2 = Factory(:member_who_has_joined_project, :project => @project, :level => "Admin")
      member2.deactivate
      user2 = member2.user
      user2.should_not be_is_admin(@project)
    end
    pending "no confirmation" do
      it "returns false if they have not joined the project" do
        member2 = Factory(:member_with_confirmed_user, :project => @project, :level => "Admin")
        member2.update_attribute(:join_code, 'somejoincode')
        user2 = member2.user
        user2.should_not be_is_admin(@project)
      end
    end
    it "- user knows he is NOT the owner/admin of someone else's project" do
      member2 = Factory(:member, :project => @project, :level => "Viewer")
      user2 = member2.user
      user2.should_not be_is_admin(@project)
      user3 = Factory(:user)
      user3.should_not be_is_admin(@project)
    end
  end

  describe "#membership_on" do
    before do
      @owner = Factory(:owner)
      @user = @owner.user
      @project = @owner.project
    end
    it "gives the unique member record that links a user to a project" do
      @user.membership_on(@project).should == @owner
    end
    it "returns nil if the user is not associated with that project" do
      other_project = Factory(:project)
      @user.membership_on(other_project).should == nil
    end
  end

  describe "#joined_and_active_on?" do
    it "returns true if user is joined and active on project" do
      owner = Factory(:owner)
      user = owner.user
      user.should be_joined_and_active_on(owner.project)
    end
    it "returns false if user is not on the project at all" do
      user = Factory(:user)
      project = Factory(:project)
      user.should_not be_joined_and_active_on(project)
    end
    pending "no confirmation" do
      it "returns false if user is on the project but hasn't joined" do
        owner = Factory(:owner)
        member = Factory(:member, :level => "Admin", :project => owner.project)
        member.update_attribute(:join_code, '123456789')
        member.user.should_not be_joined_and_active_on(member.project)
      end
    end
    it "returns false if user is on the project but has been deactivated" do
      owner = Factory(:owner)
      member = Factory(:member_who_has_joined_project, :level => "Admin", :project => owner.project)
      member.deactivate
      member.user.should_not be_joined_and_active_on(member.project)
    end
  end

  describe "membership on LLL project for new users" do
    def create_a_new_user
      @lll_project = create_lll_project
      @user = Factory(:confirmed_user)
    end

    context "on production" do
      before do
        Rails.stub(:env).and_return "production"
        create_a_new_user
      end

      it "creates LLL membership when creating new user" do
        @user.membership_on(@lll_project).should be_true
      end

      it "does not create membership if ben is not the owner of LLL project" do
        pending "this test should be written against application.rb instead"
        @lll_project.members.first.user.update_attribute(:email, 'dan@leanlaunchlab.com')
        expect { Factory(:confirmed_user) }.to_not change { @lll_project.members.count }
      end

      it "LLL permission level is Normal" do
        @user.membership_on(@lll_project).level.should == 'Normal'
      end
    end
  end

  describe "most_recent_posts" do
    before do
      @owner = Factory(:owner)
    end

    it "does not return posts to projects user is not a member of" do
      post_writer = Factory(:member_who_has_joined_project, :project => Factory(:project))
      post = Factory(:blog_post, :member => post_writer)
      @owner.user.most_recent_posts.count.should be_zero
    end

    it "returns posts from projects where user has membership in order by date descending" do
      post_writer = Factory(:member_who_has_joined_project, :project => @owner.project)
      3.times { |i| Factory(:blog_post, :member => post_writer, :published_at => Time.now - i.days, :body => i.to_s) }
      posts = @owner.user.most_recent_posts
      posts.count.should == 3
      posts.first.body.should == '0'
      posts.last.body.should == '2'
    end

    pending "no confirmation" do
      it "does not return posts from a project where user is invited but not joined" do
        project = Factory(:project)
        invite_user = Factory(:member, :user => @owner.user, :project => project)
        post_writer = Factory(:member_who_has_joined_project, :project => project)
        Factory(:blog_post, :member => post_writer)
        @owner.user.most_recent_posts.count.should be_zero
      end
    end

    it "does not return posts from a project where user is not active" do
      project = Factory(:project)
      deactivated_member = Factory(:member_who_has_joined_project, :user => @owner.user, :project => project).deactivate
      post_writer = Factory(:member_who_has_joined_project, :project => project)
      Factory(:blog_post, :member => post_writer)
      @owner.user.most_recent_posts.count.should be_zero
    end

    it "does not include the LeanLaunchLab project posts in the result set" do
      lll = create_lll_project
      join_the_lll_project @owner.user
      user = Factory(:confirmed_user)
      post_writer = user.membership_on(lll)
      post_writer.update_attribute(:level, "Admin")
      lll_post = Factory(:blog_post, :member => post_writer)
      @owner.user.most_recent_posts.count.should be_zero
    end
  end

  describe "sends welcome mail on confirmation" do

    pending "no confirmation" do
      it "sends when confirmed at changes" do
        user = Factory(:user)
        @message = double
        @message.should_receive(:deliver)
        UserMailer.should_receive(:welcome).once.with(user).and_return(@message)
        user.confirm!
      end
    end

    it "doesn't send on regular save'" do
      user = Factory(:user)
      @message = double
      UserMailer.should_not_receive(:welcome)
      user.save!
    end
  end

  describe "#new_inactive" do
    before do
      inactive_member, old_inactive_member, active_blogging_member, active_commenting_member = (1..4).map {Factory(:owner)}

      @inactive_user = inactive_member.user
      @inactive_user.update_attribute(:confirmed_at, 60.hours.ago)

      @old_inactive_user = old_inactive_member.user
      @old_inactive_user.update_attribute(:confirmed_at, 10.days.ago)

      @active_blogging_user = active_blogging_member.user
      @active_blogging_user.update_attribute(:confirmed_at, 60.hours.ago)
      Factory(:blog_post, :member => active_blogging_member)

      @active_commenting_user = active_commenting_member.user
      @active_commenting_user.update_attribute(:confirmed_at, 60.hours.ago)
      Factory(:comment, :member => active_commenting_member)
    end

    it "includes inactive_user" do
      User.new_inactive.should include(@inactive_user)
    end

    it "does not include old_inactive_user" do
      User.new_inactive.should_not include(@old_inactive_user)
    end

    it "does not include active_blogging_user" do
      User.new_inactive.should_not include(@active_blogging_user)
    end

    it "does not include active_commenting_user" do
      User.new_inactive.should_not include(@active_commenting_user)
    end

  end
end
