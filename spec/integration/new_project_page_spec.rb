#require "spec_helper"
#
#def new_project name, role_name
#  click_link "New Project"
#  wait_until { page.has_content?("PROJECT NAME") }
#  fill_in "txt-name", :with => name
#  choose role_name
#  click_button "Create Project"
#  # Note: there is no built-in pause right here after "Create Project" is clicked
#end
#
#describe "click the 'New Project' link" do
#  before do
#    create_lll_project
#    @user = Factory(:confirmed_user)
#    login_with_email_and_password @user
#  end
#
#  describe "happy path" do
#    it "creates a project" do
#      new_project "NewProject", "Other"
#      page.should have_content "NewProject"
#      page.should have_content "Other"
#      page.should have_content @user.name
#    end
#  end
#
#  describe "frowny path  :-(" do
#    it "doesn't create a project if project name is missing" do
#      pending "This failing test needs an implementation!!  See story https://www.pivotaltracker.com/story/show/19424455"
#      new_project "", "Investor"
#      page.should have_content "Name can't be blank"
#    end
#
#    it "doesn't create a project if role is missing" do
#      pending "This failing test needs an implementation!!  See story https://www.pivotaltracker.com/story/show/19424455"
#      new_project "MyProject", ""
#      page.should have_content "Role is required"
#    end
#
#    it "doesn't create a project if both are missing" do
#      pending "This failing test needs an implementation!!  See story https://www.pivotaltracker.com/story/show/19424455"
#      new_project "", ""
#      page.should have_content "Name can't be blank"
#      page.should have_content "Role is required"
#    end
#  end
#
#  describe "creating multiple projects" do
#    it "creates and displays the projects in order" do
#      new_project "New2", "Other"
#      page.should have_content "New2"
#      new_project "New1", "Other"
#      page.should have_content "New1"
#      page.html.should match /All Projects.*LeanLaunchLab.*New2.*New1/m
#    end
#  end
#end

