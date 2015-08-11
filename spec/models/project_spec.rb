require 'spec_helper'

describe Project do

  it 'should be valid' do
    valid_project = Project.new(:name => "test")
    valid_project.should be_valid
  end

  it 'factory should be valid' do
    Factory.build(:project).should be_valid
  end

  describe "validations" do
    [:name].each do |att|
      it "is not valid without presence of #{att}" do
        subject.should_not be_valid
        subject.errors[att].should_not be_empty
      end
    end

    describe "- unique project name -" do
      before do
        @existing_owner = Factory(:owner)
        @existing_project = @existing_owner.project
      end

      it "is not valid with same name as another project with same owner" do
        project = Factory.build(:project, :name => @existing_project.name, :members => [@existing_owner])
        project.should_not be_valid
      end

      it "is valid with the same name as a project with a different owner" do
        owner = Factory(:owner, :project => Factory.build(:project, :name => @existing_project.name))
        owner.project.should be_valid
      end
    end

    describe "pitch" do
      it "is not valid with more than 140 characters" do
        Project.create(Factory.attributes_for(:project, :pitch => "X" * 141)).should_not be_valid
      end

      it "is valid with 140 characters" do
        Project.create(Factory.attributes_for(:project, :pitch => "X" * 140)).should be_valid
      end
    end

    it "requires valid url" do
      Project.create(Factory.attributes_for(:project, :url => '...')).should_not be_valid
    end

    it "accepts blank urls" do
      Project.create(Factory.attributes_for(:project, :url => "")).should be_valid
    end
  end

  describe "associations" do
    it "has members" do
      subject.should respond_to(:members)
    end

    it "has users" do
      subject.should respond_to(:users)
    end

    it "has canvas_items" do
      subject.should respond_to(:canvas_items)
    end
  end

  describe "#owner" do
    it "finds the member record that represents the owner of the project" do
      Project.delete_all #TODO fix this hack; db does not seem to get cleaned by rspec
      owner1 = Factory(:owner)
      owner2 = Factory(:owner)
      project1 = owner1.project
      project2 = owner2.project
      Factory(:member, :project => project1)
      Factory(:member, :project => project2)
      Factory(:member, :user => owner2.user, :project => owner1.project, :level => 'Admin')

      # some sanity checks
      Project.count.should == 2
      Member.count.should == 5
      User.count.should == 4

      project1.owner.should == owner1
      project2.owner.should == owner2
    end
  end

  describe "members for level" do
    before(:all) do
      #@lll_project = create_lll_project ## this works if you comment out the lll_id stub in spec_helper
      @project = Factory(:project)
      @joined_member = Factory(:member_who_has_joined_project, :project => @project)
      @un_joined_member = Factory(:member, :project => @project)
    end

    it "returns all members for admins" do
      @project.members_for_level('Admin').length.should == 2
    end

    pending "no confirmation" do
      it "returns joined members for normals" do
        result = @project.members_for_level('Normal')
        result.length.should == 1
        result.should include(@joined_member)
      end
    end
    
    it "returns empty array for viewers" do
      @project.members_for_level('Viewer').should be_empty
    end

    it "returns empty array for all levels on LLL project" do
      pending "until we figure out a better way to stub lll_id this works if you comment out the stub in spec_helper"
      #LeanLaunchLab::Application.stub(:lll_id).and_return(@lll_project.id)
      @lll_project.members_for_level('Admin').should be_empty
      @lll_project.members_for_level('Normal').should be_empty
      @lll_project.members_for_level('Viewer').should be_empty
    end
  end

  describe "canvas_items_for_utc_date" do

    context "date is now" do
      it "returns only most recent canvas items before given date" do
        ci = Factory(:canvas_item, :created_at => Time.now.utc - 15.hours)
        ci2 = Factory(:canvas_item, :project => ci.project, :created_at => Time.now.utc - 15.hours)
        10.times { |i| ci.create_updated(:created_at => ci.created_at + (1+i).hours, :text => "text #{i}") }
        5.times { |i| ci2.create_updated(:created_at => ci2.created_at + (1+i).hours, :text => "text #{i}") }

        items = ci.project.canvas_items_for_utc_date(Time.now.utc, ci.box)
        items.count.should == 2
        items.first.created_at.should < Time.now.utc
        items.last.created_at.should < Time.now.utc
        items.last.should == ci.project.canvas_items.where("original_id = #{ci.original_id}").last
      end
    end

    context 'date is in the past' do
      it "returns only most recent canvas items before given date" do
        ci = Factory(:canvas_item, :created_at => Time.now.utc - 15.hours)
        ci2 = Factory(:canvas_item, :project => ci.project, :created_at => Time.now.utc - 15.hours)
        10.times { |i| ci.create_updated(:created_at => ci.created_at + (1+i).hours, :text => "text #{i}") }
        5.times { |i| ci2.create_updated(:created_at => ci2.created_at + (1+i).hours, :text => "text #{i}") }

        snapshot_time = ci.created_at + 3.hours
        items = ci.project.canvas_items_for_utc_date(snapshot_time, ci.box)
        items.count.should == 2
        items.first.created_at.should < snapshot_time
        items.last.created_at.should < snapshot_time
        items.first.should == ci.project.canvas_items.where("original_id = #{ci.original_id}")[2]
        items.last.should == ci.project.canvas_items.where("original_id = #{ci2.original_id}")[2]
      end
    end

    it "handles dates near both sides of the week end time" do
      sunday_midnight = Time.parse("2011-08-07 23:59:59 UTC")
      end_of_previous_week = sunday_midnight - 1.minute
      beginning_of_this_week = sunday_midnight + 1.minute
      item1 = Factory(:canvas_item, :text => 'last weeks item', :created_at => end_of_previous_week)
      box = item1.box
      project = item1.project
      project.update_attribute(:created_at, sunday_midnight - 2.weeks)
      Factory(:canvas_item, :created_at => beginning_of_this_week, :project => project, :text => 'this weeks item')
      previous_week = sunday_midnight.to_date
      this_week = previous_week + 7.days
      # now, simulate what ProjectsHelper does
      this_sunday_midnight = this_week.end_of_day
      this_weeks_items = project.canvas_items_for_utc_date(this_sunday_midnight, box)
      previous_sunday_midnight = previous_week.end_of_day
      previous_weeks_items = project.canvas_items_for_utc_date(previous_sunday_midnight, box)
      this_weeks_items.count.should == 2
      previous_weeks_items.count.should == 1
    end
  end

  describe "blog_post_needing_feedback_count" do
    it "returns the number of blog posts that the member hasn't commented on" do
      owner = Factory(:owner)
      member = Factory(:member_who_has_joined_project, :project => owner.project)
      blog_post1 = Factory(:blog_post, :member => member)
      blog_post2 = Factory(:blog_post, :member => member)
      Factory(:comment, :blog_post => blog_post2, :member => member)
      owner.project.blog_post_needing_feedback(owner).count.should == 2
    end

    it "does not include blog posts written by the member" do
      owner = Factory(:owner)
      blog_post1 = Factory(:blog_post, :member => owner)
      blog_post2 = Factory(:blog_post, :member => owner)
      owner.project.blog_post_needing_feedback(owner).count.should == 0
    end
  end

  describe "delta method" do
    before do
      @canvas_item = Factory(:canvas_item, :created_at => Date.parse('2011-07-02'))
      @project = @canvas_item.project
      @project.update_attribute(:created_at, Date.parse('2011-07-01'))
    end

    it "includes newly added items in the return value when project start is today" do
      @project.update_attribute(:created_at, Date.today)
      @canvas_item.update_attribute(:created_at, Date.today)
      actual = @project.canvas_items_delta(Date.today.end_of_week, @canvas_item.box)
      actual.should == [@canvas_item]
      actual.first.delta_deleted.should be_false
      actual.first.delta_added.should be_true
      actual.first.delta_changed.should be_false
    end

    it "includes newly added items in the return value" do
      @canvas_item.update_attribute(:created_at, Date.today)
      actual = @project.canvas_items_delta(Date.today.end_of_week, @canvas_item.box)
      actual.should == [@canvas_item]
      actual.first.delta_deleted.should be_false
      actual.first.delta_added.should be_true
      actual.first.delta_changed.should be_false
    end

    it "shows one item with no strikeout or outline if the item exists in both weeks unchanged" do
      actual = @project.canvas_items_delta(Date.today.end_of_week, @canvas_item.box)
      actual.should == [@canvas_item]
      actual.first.delta_deleted.should be_false
      actual.first.delta_added.should be_false
      actual.first.delta_changed.should be_false
    end

    it "includes items deleted since last week" do
      @canvas_item.create_updated(:deleted => true)
      actual = @project.canvas_items_delta(Date.today.end_of_week, @canvas_item.box)
      actual.should == [@canvas_item]
      actual.first.delta_deleted.should be_true
      actual.first.delta_added.should be_false
      actual.first.delta_changed.should be_false
    end

    it "shows two items to represent a single item that had its text modified" do
      canvas_item_updated = @canvas_item.create_updated(:text => 'new text')
      actual = @project.canvas_items_delta(Date.today.end_of_week, @canvas_item.box)
      actual.should == [@canvas_item, canvas_item_updated]
      actual.first.delta_deleted.should be_true
      actual.first.delta_added.should be_false
      actual.first.delta_changed.should be_true
      actual.last.delta_deleted.should be_false
      actual.last.delta_added.should be_true
      actual.last.delta_changed.should be_true
    end

    it "regards an item as unchanged if it was changed in some way, then set back to the way it was originally" do
      original_text = @canvas_item.text
      @canvas_item.create_updated(:text => 'edited')
      @canvas_item.create_updated(:text => original_text)
      actual = @project.canvas_items_delta(Date.today.end_of_week, @canvas_item.box)
      actual.first.delta_deleted.should be_false
      actual.first.delta_added.should be_false
      actual.first.delta_changed.should be_false
    end

    context "the whole enchilada" do
      it "orders multiple items correctly" do
        3.times { |i| Factory(:canvas_item, :created_at => Date.parse('2011-07-02') + (i+1).days, :project => @project) }
        previous_weeks_items = CanvasItem.order(:id).to_a
        previous_weeks_items[0].create_updated(:deleted => true)
        previous_weeks_items[1].create_updated(:text => 'some new text')
        edited_item = previous_weeks_items[3].create_updated(:item_status_id => ItemStatus[:valid])
        edited_item.create_updated(:item_status_id => ItemStatus[:unknown])
        new_item = Factory(:canvas_item, :project => @project)
        actual = @project.canvas_items_delta(Date.today.end_of_week, @canvas_item.box)
        actual.count.should == 6

        actual[0].original_id.should == previous_weeks_items[0].original_id
        actual[0].delta_deleted.should be_true
        actual[0].delta_added.should be_false
        actual[0].delta_changed.should be_false

        actual[1].original_id.should == previous_weeks_items[1].original_id
        actual[1].delta_deleted.should be_true
        actual[1].delta_added.should be_false
        actual[1].delta_changed.should be_true

        actual[2].original_id.should == previous_weeks_items[1].original_id
        actual[2].delta_deleted.should be_false
        actual[2].delta_added.should be_true
        actual[2].delta_changed.should be_true

        actual[3].id.should == previous_weeks_items[2].id
        actual[3].delta_deleted.should be_false
        actual[3].delta_added.should be_false
        actual[3].delta_changed.should be_false

        actual[4].original_id.should == previous_weeks_items[3].original_id
        actual[4].delta_deleted.should be_false
        actual[4].delta_added.should be_false
        actual[4].delta_changed.should be_false

        actual[5].should == new_item
        actual[5].delta_deleted.should be_false
        actual[5].delta_added.should be_true
        actual[5].delta_changed.should be_false

      end
    end
  end

  describe "#posts_since(time)" do
    before { @project = Factory(:project) }

    describe "with no new posts" do

      it "is empty " do
        @project.posts_since(Time.now.utc - 100.years).should be_empty
      end
    end

    describe "with new posts" do
      before do
        @now = Time.now.utc
        author = Factory(:member_who_has_joined_project, :project => @project)
        @new_post = Factory(:blog_post, :member => author, :published_at => @now - 1.day)
        old_post = Factory(:blog_post, :member => author, :published_at => @now - 10.days)
      end

      it "returns posts newer than time passed" do
        result = @project.posts_since(@now - 2.days)
        result.count.should == 1
        result.first.should == @new_post
      end

      it "does not return posts older than time passed" do
        result = @project.posts_since(@now)
        result.count.should == 0
      end

    end
  end
end
