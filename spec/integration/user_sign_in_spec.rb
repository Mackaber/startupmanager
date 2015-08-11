require "spec_helper"

describe "User sign in" do
  after do
    visit destroy_user_session_path # sign out
  end

  context "user is unconfirmed (hasn't clicked the email link)" do
    
    pending "no confirmation" do
      describe "user signed up on his own" do

        it 'goes to the need_email_confirmation page after sign up' do
          visit new_user_registration_path
          fill_in 'user_name', :with => 'joe_blow'
          fill_in 'user_email', :with => 'joe@blow.com'
          fill_in 'user_password', :with => 'password'
          fill_in 'user_password_confirmation', :with => 'password'
          click_link 'Sign Up'
          page.should have_content 'Please check your email'
        end
      end
    end

    describe "user was invited by a project owner" do
      before do
        @user = create_an_unconfirmed_user "joe", "joe@blow.com"
      end

      # TODO: is this necessary?  Maybe just factory a confirmed user ...
      # This seems like it could be a nice test in and of itself, in some other spec file perhaps
      def create_an_unconfirmed_user name, email
        owner = Factory(:owner)
        login_with_email_and_password owner.user
        click_link "Invite Member"
        wait_until { page.has_selector?("input#txt-email") }
        select(owner.project.name, :from => 'member_project_id')
        fill_in 'NAME', :with => name
        fill_in 'EMAIL', :with => email
        choose "Admin"
        choose "Other"
        click_link "Create Member"
        click_link 'Log Out'
        wait_until { page.has_selector?("form.sign-in-form") }
        User.last
      end

      it "goes to the 'need_email_confirmation page' after sign up" do
        pending "this doesn't work with devise 1.5+"
        login_with_email_and_password @user #, "this is not joe's correct password"
        page.should have_content 'This email address has not been confirmed yet'
        click_link "Resend the confirmation email"
        page.should have_content "Please check your email"
      end
    end
  end

  describe "first time sign in" do
    it "goes to the 'new project page' if user does not belong to any projects" do
      @user = Factory(:confirmed_user)
      login_with_email_and_password @user
      wait_until { page.has_content?("ALL UPDATES") }
      current_path.should == projects_path
    end
  end

  describe "Redirect unauthenticated users" do
    before do
      @owner = Factory(:owner)
      @user = @owner.user
      @project1 = @owner.project
    end

    context 'user not logged in' do #capybara seems to want a context for "visit" to work
      describe "forwarding to the requested page after sign in" do
        it "forwards to project page" do
          visit project_path(@owner.project_id)
          current_path.should == new_user_session_path
          login_with_email_and_password @user
          current_path.should == project_path(@owner.project_id)
        end

        it "forwards to edit settings page" do
          visit edit_settings_path
          current_path.should == new_user_session_path
          login_with_email_and_password @user
          current_path.should == edit_settings_path
        end
      end
    end

    describe "successful sign in" do
      it "redirects to the project page for the most recently visited project" do
        membership1 = @owner
        project2 = Factory(:project)
        membership2 = Factory(:member_who_has_joined_project, :user => @user, :project => project2)
        project3 = Factory(:project)
        membership3 = Factory(:member_who_has_joined_project, :user => @user, :project => project3)
        login_with_email_and_password @user
        click_link(project2.name)
        click_link('Log Out')
        login_with_email_and_password @user
        wait_until { current_path =~ /\/projects\/#{project2.id}-/ }
      end
    end
  end
end
