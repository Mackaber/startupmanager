require 'spec_helper'

describe UsersController do

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = Factory(:confirmed_user)
  end

  context "when user logged in" do

    before do
      sign_in @user
    end

    describe "GET edit" do
      it "assigns user " do
        get :edit, :id => @user.id
        assigns(:user).should == @user
      end
    end

    describe "GET edit_settings" do
      it "assigns user " do
        get :edit_settings, :id => @user.id
        assigns(:user).should == @user
      end
    end

    describe "PUT update_setting" do

      describe "with valid params" do

        it "assigns user" do
          put :update_setting, :id => @user.id
          assigns[:user].should == @user
        end

        it "updates name" do
          put :update_setting, :user => {:name => "XXXX"}
          @user.reload.name.should == "XXXX"
        end
      end

      describe "with invalid params" do
        before do
          put :update_setting, :user => {:password => "short"}
        end

        it "gives a flash message" do
          flash[:error].should =~ /too short/
        end

        it "re renders the page" do
          response.should render_template :edit_settings
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do

        describe "changing the user name" do
          before do
            put :update, :id => @user.id, :user => {:name => 'XXX'}
          end

          it "updates the user" do
            # TODO: need some assertions on password
            @user.reload.name.should == 'XXX'
          end

          it "renders the edit template" do
            response.should redirect_to current_user_path
          end
        end

        it "updates the password" do
          encrypted = @user.encrypted_password
          put :update, :id => @user.id, :user => {:password => "new_password", :password_confirmation => "new_password"}
          response.should redirect_to current_user_path
          @user.reload.encrypted_password.should_not == encrypted
        end

      end

      describe "with invalid params" do

        before do
          @parameters = {:id => @user.id, :user => {:name => 'XXX', :password => 'password', :password_confirmation => 'password'}}
        end

        [:name, :password, :password_confirmation].each do |attr|
          it "displays flash message if #{attr} is blank" do
            @parameters[:user][attr] = ''
            put :update, @parameters
            flash[:error].should_not be_nil
          end
        end
      end
    end

    describe "get last_visited_project" do

      it "goes to All Projects view if no viewed posts" do
        get :last_visited_project
        response.should redirect_to projects_path
      end

      it "goes to All Projects if cookie is set to a project they don't have membership on " do
        project_user_not_member_of = Factory(:project)
        request.cookies['last_project'] = project_user_not_member_of.id
        get :last_visited_project
        response.should redirect_to projects_path
      end

      it "goes to last visited project where the last blog post was viewed" do
        project = Factory(:project)
        member = Factory(:member_who_has_joined_project, :user => @user, :project => project)
        request.cookies['last_project'] = project.id
        get :last_visited_project
        response.should redirect_to project_path(project)
      end
    end

    describe "need_email_confirmation" do
      before do
        get :need_email_confirmation, :email => "xxx@example.com"
      end

      it "renders the need email confirmation page" do
        response.should render_template "need_email_confirmation"
      end

      it "assigns user" do
        assigns(:user).should be_kind_of(User)
      end
    end
  end

  context "when user is not logged in" do

    it "redirects to sign in page when attempting to edit settings" do
      get :edit_settings
      response.should redirect_to new_user_session_path
    end

    it "redirects to sign in page when attempting to update settings" do
      put :update_setting, {"setting"=>{"post_email"=>"1", "feedback_email"=>"1", "digest_email"=>"0"}, "id"=>"21"}
      response.should redirect_to new_user_session_path
    end
  end
end
