require 'spec_helper'

describe Member do
  describe "creation" do
    context 'new unconfirmed user' do
      it 'should not have nil join_code' do
        owner = Factory(:owner)
        member = Factory(:member, :project => owner.project)
        member.join_code.should_not be_nil
      end
    end

    context 'existing confirmed user' do
      it "- a confirmed non-owner has join_code populated" do
        owner = Factory(:owner)
        member = Factory(:member_with_confirmed_user, :project => owner.project)
        member.join_code.should_not be_nil
      end

      it "- a new owner has join_code nil" do
        owner = Factory(:owner)
        owner.join_code.should be_nil
      end
    end
  end

  describe "validations" do
    before do
      owner = Factory(:owner)
      @member = Factory.build(:member, :project => owner.project)
    end

    it 'should not be valid if a member record already exists with the same user and project' do
      owner = Factory.create(:owner)

      owner2 = Factory.build(:owner, :user => owner.user, :project => owner.project)
      owner2.should_not be_valid
    end

    it "is valid" do
      @member.should be_valid
    end

    [:level, :role_name].each do |attr|
      it "is not valid without presence of #{attr}" do
        @member[attr] = nil
        @member.should_not be_valid
      end
    end

    it "level cannot be an arbitrary value" do
      @member[:level] = "my arbitrary value"
      @member.should_not be_valid
    end

    it "role_name cannot be an arbitrary value" do
      @member[:role_name] = "my arbitrary value"
      @member.should_not be_valid
    end

  end

  pending "no confirmation" do
    describe "joined_project scope" do
      it "returns all members of the project who have accepted their invitations" do
        owner = Factory(:owner)

        member = Factory(:member, :project => owner.project, :join_code => '12341234')
        owner.project.reload
        Member.joined_project(owner.project).count.should == 1
      end
    end
  end

  describe "#deactivate" do
    it "deactivates a member who is not the owner" do
      owner = Factory(:owner)
      member = Factory(:member, :project => owner.project, :level => "Admin")
      member.should be_activated
      member.deactivate
      member.should_not be_activated
    end

    it "doesn't deactivate the project owner" do
      owner = Factory(:owner)
      owner.deactivate
      owner.should be_activated
    end
  end

  describe "#unjoined_for(days)" do
    before do
      @now = Time.now.utc
      (1..4).each { |i| m = Factory(:member_who_has_joined_project, :created_at => @now - i.days,
                                :project => Factory(:project))
        m.user.update_attribute(:name, "#joined #{i} days ago")
      }
    end

    pending "no confirmation" do
      describe "null case" do

        it "returns nothing when no unjoined users" do
          Member.unjoined_for(2).should be_empty
        end
      end
    end

    describe "non-null cases" do
      before do
        (1..6).each { |i| m = Factory(:member, :created_at => @now - i.days, :project => Factory(:project))
        m.user.update_attribute(:name, "unjoined for #{i} days")
        }
      end

      pending "no confirmation" do
        it "returns member unjoined for two days" do
          result = Member.unjoined_for(2)
          result.count.should == 1
          result.first.user.name.should == "unjoined for 2 days"
        end

        it "returns member unjoined for seven days" do
          result = Member.unjoined_for(5)
          result.count.should == 1
          result.first.user.name.should == "unjoined for 5 days"
        end
      end
    end
  end

end
