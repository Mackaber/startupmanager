require "spec_helper"

describe BlogPost do
  describe 'validations' do
    it "is valid" do
      owner = Factory(:owner)
      valid_blog_post = BlogPost.new(:project => owner.project, :member => owner, :subject => "My Test Blog Entry", :body => "lorem ipsum ... ", :the_ask => "Just FYI")
      valid_blog_post.should be_valid
    end

    it "factory is valid" do
      Factory.build(:blog_post).should be_valid
    end
    
    [:project].each do |att|
      it "is not valid without #{att}" do
        pending "blog post requires either project, task, hypothesis, or experiment"
        subject.should_not be_valid
        subject.errors[att].should_not be_empty
      end
    end

    [:subject, :member].each do |att|
      it "is not valid without #{att}" do
        subject.should_not be_valid
        subject.errors[att].should_not be_empty
      end
    end

    it "is invalid if associated key learning is invalid" do
      invalid_key_learning = Factory.build(:learning, :content => 'X'*251)
      post = Factory.build(:blog_post, :learnings => [invalid_key_learning])
      post.should_not be_valid
    end
  end

  describe "associations" do
    it "has_many post_items" do
      subject.should respond_to :post_items
    end
    it "has_many boxes" do
      subject.should respond_to :boxes
    end
    it "has_many canvas_items" do
      subject.should respond_to :canvas_items
    end
  end

  describe "nested_attributes_for" do
    it "builds associated post_item" do
      project = Factory(:project)
      canvas_item = Factory(:canvas_item, :project_id => project.id)
      attributes = Factory.attributes_for(:blog_post, :project => project).merge({:post_items_attributes => {"0" => {:canvas_item_id => canvas_item.id}}})
      expect { BlogPost.create(attributes) }.to change { PostItem.count }.by(1)
    end
  end

  describe "truncation" do
    it "shortens the subject down to 250 characters if it's longer" do
      blog_post = Factory(:blog_post, :subject => "X" * 251)
      blog_post.subject.length.should == 250
    end
  end

  describe "#unread_comments" do
    before do
      @owner = Factory(:owner)
      @project = @owner.project
      @blog_post = Factory(:blog_post, :member => @owner)
    end

    describe "total count" do
      it 'returns 1 unread comment for the blog post owner' do
        member = Factory(:member_who_has_joined_project, :project => @project)
        comment = Factory(:comment, :blog_post => @blog_post, :member => member)

        @blog_post.unread_comments(@owner)[:total_count].should == 1
      end

      it 'returns multiple unread comments for the blog post owner' do
        member = Factory(:member_who_has_joined_project, :project => @project)
        Factory(:comment, :blog_post => @blog_post, :member => member)
        Factory(:comment, :blog_post => @blog_post, :member => member)
        Factory(:comment, :blog_post => @blog_post, :member => member)
        Factory(:comment, :blog_post => @blog_post, :member => member)

        @blog_post.unread_comments(@owner)[:total_count].should == 4
      end
    end

    describe "count by name" do

      it 'returns the count for a specific user' do
        member = Factory(:member_who_has_joined_project, :project => @project)
        Factory(:comment, :blog_post => @blog_post, :member => member)

        @blog_post.unread_comments(@owner)[:count_for_users].count.should == 1
        @blog_post.unread_comments(@owner)[:count_for_users].first.name.should == member.user.name
        @blog_post.unread_comments(@owner)[:count_for_users].first.count.should == "1"
      end

      it "doesn't return comments that the user has already seen" do
        member = Factory(:member_who_has_joined_project, :project => @project)
        comment = Factory(:comment, :blog_post => @blog_post, :member => member)
        MemberBlogPostView.create!(:member => @owner, :blog_post => @blog_post)
        member2 = Factory(:member_who_has_joined_project, :project => @project)
        member2.user.update_attribute(:name, 'Sally')
        comment2 = Factory(:comment, :blog_post => @blog_post, :member => member2)

        @blog_post.unread_comments(@owner)[:count_for_users].first.count.should == "1"
        @blog_post.unread_comments(@owner)[:count_for_users].map(&:name).should_not include member.user.name
      end

      it "doesn't return comments written by the user" do
        member = Factory(:member_who_has_joined_project, :project => @project)
        member.user.update_attribute(:name, 'Sally')
        comment1 = Factory(:comment, :blog_post => @blog_post, :member => member)
        comment2 = Factory(:comment, :blog_post => @blog_post, :member => @owner)

        @blog_post.unread_comments(@owner)[:total_count].should == 1
        @blog_post.unread_comments(@owner)[:count_for_users].map(&:name).should_not include @owner.user.name
      end

      it "doesn't return comments written by the user if the user has viewed the post" do
        member = Factory(:member_who_has_joined_project, :project => @project)
        member.user.update_attribute(:name, 'Sally')
        MemberBlogPostView.create!(:member => @owner, :blog_post => @blog_post)
        comment = Factory(:comment, :blog_post => @blog_post, :member => member)
        comment2 = Factory(:comment, :blog_post => @blog_post, :member => @owner)

        @blog_post.unread_comments(@owner)[:total_count].should == 1
        @blog_post.unread_comments(@owner)[:count_for_users].map(&:name).should_not include @owner.user.name
      end
    end

    it 'is empty for viewer users' do
      viewer = Factory(:member_who_has_joined_project, :project => @project)
      member = Factory(:member_who_has_joined_project, :project => @project)
      comment = Factory(:comment, :blog_post => @blog_post, :member => member)
      @blog_post.unread_comments(viewer)[:total_count].should be_zero
    end
  end

  describe "#mail_to" do
    before do
      @owner = Factory(:owner)
      @blog_post = BlogPost.new(:project => @owner.project, :member => @owner,
                                :subject => "turtles down",
                                :body => "The world is flat and stands on a turtle.  Below that it's turtles all the way down.")
    end

    it "is empty if the only member on the project is the owner" do
      some_dude_on_another_project = Factory(:member_who_has_joined_project)
      @blog_post.mail_to.should == ""
    end

    it "is empty if the only other member is deactivated" do
      deactivated_member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Normal")
      deactivated_member.update_attribute(:activated, false)
      @blog_post.mail_to.should == ""
    end

    pending "no confirmation" do
      it "is empty if the only other member hasn't joined the project" do
        non_joined_member = Factory(:member, :project => @owner.project, :level => "Normal")
        @blog_post.mail_to.should == ""
      end
    end
    
    it "is empty if the only other member has a permission level of Viewer" do
      viewer_member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => 'Viewer')
      @blog_post.mail_to.should == ""
    end

    it "is a single email address if there is exactly one other member on the project" do
      admin = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Admin")
      @blog_post.mail_to.should == admin.user.email
    end

    it "is a comma-separated string of several email addresses if there are other members on the project" do
      normal = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Normal")
      normal2 = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Normal")
      viewer = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Viewer")
      mail_to = @blog_post.mail_to
      mail_to.should match /#{normal.user.email}/
      mail_to.should match /#{normal2.user.email}/
      mail_to.should_not match /#{viewer.user.email}/
      mail_to.split(',').count.should == 2
    end

    it 'does not include members who have set their post_email preference to false' do
      no_mail_member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Normal")
      wants_mail_member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Normal")
      no_mail_member.user.setting.update_attribute(:post_email, false)
      @blog_post.mail_to.should_not include(no_mail_member.user.email)
      @blog_post.mail_to.should include(wants_mail_member.user.email)
    end
  end

  describe "creation" do
    before do
      @owner = Factory(:owner)
    end

    describe 'learnings' do

      describe "learnings blob setter" do
        before do
          @blog_post = BlogPost.new(:project => @owner.project, :member => @owner,
                                    :subject => "turtles", :body => "I like turtles",
                                    :the_ask => "Just FYI")
        end

        it 'creates learnings' do
          expect {
            @blog_post.learnings_blob = "Learning 1\r\nLearning 2"
            @blog_post.save!
          }.to change { Learning.count }.by(2)
        end

        it "doesn't create learning with a trailing carriage return" do
          expect {
            @blog_post.learnings_blob = "Learning 1\r\n"
            @blog_post.save!
            @blog_post.learnings.first.content.should == "Learning 1"
          }.to change { Learning.count }.by(1)
        end

        it "doesn't create learning that is a space" do
          expect {
            @blog_post.learnings_blob = "Learning 1\r\n "
            @blog_post.save!
            @blog_post.learnings.first.content.should == "Learning 1"
          }.to change { Learning.count }.by(1)
        end

        it "doesn't create learning that is a tab" do
          expect {
            @blog_post.learnings_blob = "Learning 1\r\n\t"
            @blog_post.save!
            @blog_post.learnings.first.content.should == "Learning 1"
          }.to change { Learning.count }.by(1)
        end

        it "strips leading space" do
          @blog_post.learnings_blob = " Learning 1"
          @blog_post.save!
          @blog_post.learnings.first.content.should == "Learning 1"
        end

        it "works with just newline" do
          expect {
            @blog_post.learnings_blob = "Learning 1\nLearning 2"
            @blog_post.save!
            @blog_post.learnings.first.content.should == "Learning 1"
          }.to change { Learning.count }.by(2)
        end
      end

    end

    it 'should send email to all project members' do
      message = double
      message.should_receive(:deliver)
      BlogPostMailer.should_receive(:mail_contents_of_blog_post).and_return(message)

      owner = Factory(:owner)
      Factory(:member_who_has_joined_project, :project => owner.project, :level => "Admin")
      post = BlogPost.create!(:project => owner.project, :member => owner,
                       :subject => "turtles", :body => "I like turtles", :the_ask => "Just FYI")
      post.publish!
    end

    context "zero recipients" do
      before do
        BlogPostMailer.should_not_receive(:mail_contents_of_blog_post)
        @owner = Factory(:owner)
      end
      it 'should not attempt to send email if poster is the only member' do
        BlogPost.create(:project => @owner.project, :member => @owner, :subject => "turtles", :body => "I like turtles")
      end

      it 'should not attempt to send email if poster is the only _joined_ member' do
        Factory(:member, :project => @owner.project, :join_code => 'not joined')
        BlogPost.create(:project => @owner.project, :member => @owner, :subject => "turtles", :body => "I like turtles")
      end

      it 'should not attempt to send email if poster is the only _activated_ member' do
        other_member = Factory(:member, :project => @owner.project)
        other_member.update_attribute(:activated, false)
        BlogPost.create(:project => @owner.project, :member => @owner, :subject => "turtles", :body => "I like turtles")
      end
    end
  end

  describe 'update' do
    before do
      @owner = Factory(:owner)
      @blog_post = BlogPost.create!(:project => @owner.project, :member => @owner,
                                    :subject => "turtles", :body => "I like turtles", :the_ask => "Just FYI")
    end

    describe 'learnings' do

      it 'should parse learnings and create objects' do
        learnings_blob = "Learning 1\nLearning 2"
        @blog_post.learnings_blob = learnings_blob
        @blog_post.save
        @blog_post.reload.learnings.count.should == 2
        @blog_post.learnings.first.content.should == "Learning 1"
        @blog_post.learnings.last.content.should == "Learning 2"
      end

      it 'should delete existing learnings and create the new ones' do
        Factory(:learning, :blog_post => @blog_post, :content => "Learning 1")

        #TODO: why do we have to do this here? it is already reloaded in the factory
        @blog_post.reload

        learnings_blob = "Learning 2"
        @blog_post.learnings_blob = learnings_blob
        @blog_post.save
        @blog_post.reload.learnings.count.should == 1
        @blog_post.learnings.last.content.should == "Learning 2"
      end

      it 'should delete learnings if learnings were deleted' do
        Factory(:learning, :blog_post => @blog_post, :content => "Learning 1")

        #TODO: why do we have to do this here? it is already reloaded in the factory
        @blog_post.reload

        learnings_blob = ""
        @blog_post.learnings_blob = learnings_blob
        @blog_post.save
        @blog_post.reload.learnings.should be_empty
      end
    end
  end


  describe "new_comments" do
    before do
      @post = Factory(:blog_post)
      unrelated_comment = Factory(:comment, :body => 'unrelated comment')
      names = %w(Dan Abe Curtis Eric Fred Ben)
      now = Time.now
      (names.length).times do |i|
        user = Factory(:user, :name => names[i])
        member = Factory(:member_who_has_joined_project, :project => @post.project, :user => user)
        Factory(:comment, :blog_post => @post, :created_at => now - (i * 7).hours, :member => member)
      end
    end

    it "lists authors of comments made in the last 24 hours, in order by first name" do
      @post.new_comment_authors.should == %w(Abe Curtis Dan Eric)
    end

    it "does not list an author more than once" do
      author = @post.project.members.first
      3.times { |i| Factory(:comment, :blog_post => @post, :created_at => Time.now - i.hours, :member => author) }
      @post.new_comment_authors.split(author.user.name).count.should == 2
    end
  end

end
