require "spec_helper"
require 'cmd.rb'

describe Cmd do
  it "says hello" do
    Cmd.hello.should == "method 'hello' was called, it wrote 'Hello World' to stdout"
  end

  describe "membership creation" do
    before do
      @lll_project = create_lll_project
      @owner = Factory(:owner)
      @project = @owner.project
    end

    it "adds the user to the project" do
      @user = Factory(:confirmed_user)
      @user.membership_on(@lll_project).should_not be_nil
      @user.membership_on(@project).should be_nil

      Cmd.create_member(@project.id, @user.id)
      @project.reload # need to refresh the members collection !
      member = @user.membership_on(@project)
      member.should_not be_nil
      member.user_id.should == @user.id
      member.project_id.should == @project.id
      member.role_name.should == "Other"
      member.level.should == "Normal"
    end

    it "adds several users to the project" do
      projects = [@project, Factory(:project, :name => "PROJ1"), Factory(:project, :name => "PROJ2")]
      users = [@owner.user, Factory(:confirmed_user, :name => "USER1"), Factory(:confirmed_user, :name => "USER2"), Factory(:confirmed_user, :name => "USER3")]
      p_ids = projects.map(&:id)
      u_ids = users.map(&:id)
      result = Cmd.create_many_members(p_ids, u_ids, "Advisor", "Normal")
      result.should == "FINISHED - performed 12 iterations, created 11 member records"
      projects.each do |project|
        project.reload
        users.each do |user|
          member = user.membership_on(project)
          member.should_not be_nil
          if user == @owner.user && project == @owner.project
            member.level.should == "Admin"
          else
            member.role_name.should == "Advisor"
            member.level.should == "Normal"
          end
        end
      end
    end
  end
end

__END__

example project ids:
[510, 511, 512, 513, 514, 515, 516, 518, 519, 520, 521, 523, 524, 525, 526, 527, 528, 529, 539, 540, 541]

example user ids:
[20, 37, 16, 21, 1260, 1263, 1262, 1265]


require "#{Rails.root}/lib/cmd"
Cmd.hello
p_ids = [510 ,511,512,513,514,515,516,518 ,519 ,520 ,521 ,523 ,524 ,525 ,526 ,527 ,528 ,529 ,539 ,540 ,541]
u_ids = [1313]
Cmd.create_many_members(p_ids, u_ids, "Advisor", "Normal")
