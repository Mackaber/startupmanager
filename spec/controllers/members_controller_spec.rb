require 'spec_helper'

describe MembersController do
  include Devise::TestHelpers

  describe "DELETE destroy" do
    before do
      @owner = Factory(:owner)
      @project = @owner.project
      @viewer_to_delete = Factory(:member_who_has_joined_project, :project => @project, :level => 'Viewer')
    end

    context 'no signed in user' do
      it 'does not deactivate the member' do
        member = Factory(:member_who_has_joined_project, :project => @project, :level => "Admin")
        delete :destroy, :project_id => @project.id, :id => @viewer_to_delete.id
        @viewer_to_delete.reload.should be_activated
        response.should redirect_to new_user_session_path
      end
    end

    context 'signed in user' do
      before do
        request.env["devise.mapping"] = Devise.mappings[:user]
        @user = Factory(:confirmed_user)
        sign_in @user
      end

      context 'user who is a member of the project' do

        describe 'level restrictions' do
          %w(Normal Viewer).each do |level|
            it "#{level} cannot deactivate a member of the project" do
              member = Factory(:member_who_has_joined_project, :project => @project, :user => @user, :level => level)
              delete :destroy, :project_id => @project.id, :id => @viewer_to_delete.id
              @viewer_to_delete.reload.should be_activated
            end
          end
        end

        context 'admin member' do
          before do
            @member = Factory(:member_who_has_joined_project, :project => @project, :user => @user, :level => "Admin")
          end

          it 'deactivates the member' do
            delete :destroy, :project_id => @project.id, :id => @viewer_to_delete.id
            @viewer_to_delete.reload.should_not be_activated
          end

          it "response redirects to project page" do
            delete :destroy, :project_id => @project.id, :id => @viewer_to_delete.id
            response.should redirect_to(project_path(@project))
          end

          it "displays a flash message '<name> has been deleted from <project_name>'" do
            delete :destroy, :project_id => @project.id, :id => @viewer_to_delete.id
            flash[:notice].should =~ /#{@viewer_to_delete.user.name} has been deleted from #{@project.name}/
          end

          it "does not deactivate project owner" do
            delete :destroy, :project_id => @project.id, :id => @owner.id
            @owner.reload.should be_activated
          end

          it "cannot deactivate themselves" do
            delete :destroy, :project_id => @project.id, :id => @member.id
            @member.reload.should be_activated
          end

          it 'can remove another admin' do
            admin_to_delete = Factory(:member_who_has_joined_project, :project => @project, :level => 'Admin')
            delete :destroy, :project_id => @project.id, :id => admin_to_delete.id
            admin_to_delete.reload.should_not be_activated
          end
        end
      end

      context 'user who is not a member of the project' do
        it "when user is not related to the project at all" do
          owner = Factory(:owner)
          delete :destroy, :project_id => owner.project.id, :id => 1
          response.should redirect_to current_user_path
        end

        it "when the user has not joined the project" do
          owner = Factory(:owner)
          member = Factory(:member, :project => owner.project, :user => @user, :level => 'Viewer')
          delete :destroy, :project_id => owner.project.id, :id => 1
          response.should redirect_to current_user_path
        end

        it "when the user has been deactivated" do
          owner = Factory(:owner)
          member = Factory(:member_who_has_joined_project, :user => @user, :level => "Admin", :project => owner.project)
          member.deactivate
          delete :destroy, :project_id => owner.project.id, :id => 1
          response.should redirect_to current_user_path
        end
      end

    end
  end

  describe "POST create" do

    before do
      @owner = Factory(:owner)
      @project = @owner.project

      @parameters = {"user"=>{"email"=>"peter@gmail.com", "name"=>"Peter The Great"},
                     "member"=>{"level" => "Viewer", "role_name" => "Other"},
                     "project_id" => @project.id}
    end

    context 'no signed in user' do
      it 'should not create the member' do
        expect { post :create, @parameters }.to_not change { Member.count }
      end
    end

    context 'signed in user' do
      before do
        request.env["devise.mapping"] = Devise.mappings[:user]
        @user = Factory(:confirmed_user)
        sign_in @user
      end

      context 'user is member of the project' do

        describe 'level restrictions' do
          %w(Normal Viewer).each do |level|
            it "should not add a new member if current user is a #{level}" do
              Factory(:member_who_has_joined_project, :project => @project, :user => @user, :level => level)
              expect { post :create, @parameters }.to_not change { Member.count }
            end
          end
        end

        context 'Admin level' do

          before do
            @owner.user = @user
            @owner.save!
            @project.reload
          end

          describe 'invalid email' do
            before do
              @parameters["user"]["email"] = "this is not a valid email address!"
            end

            it "does not change the member count" do
              expect { post :create, @parameters }.to_not change { Member.count }
            end

            it "puts up a flash message" do
              post :create, @parameters
              flash[:error].should =~ /email/i
            end
          end

          context 'create member for new user' do
            it "adds a completely new user as a member to a project" do
              expect { post :create, @parameters }.to change {
                @project.reload.members.count
              }.by(1)
              pending "not using confirmation" do
                Member.last.user.confirmed?.should be_false
              end
              Member.last.join_code.should_not be_nil
              Member.last.user.has_changed_password?.should be_false
            end

            pending "not using confirmation" do
              it "sends a confirmation email" do
                message = double

                message.should_receive(:deliver)
                Devise.mailer.should_receive(:confirmation_instructions).and_return(message)
                post :create, @parameters
              end
            end

            it "creates a UserActivity record" do
              expect { post :create, @parameters }.should change(UserActivity, :count).by(1)
              user = User.last
              user_activity = UserActivity.last
              user_activity.description.should == "#{@owner.user.name} invited #{user.name} to project #{@project.name}"
              user_activity.action.should == "Invited"
              user_activity.member.should == @owner
            end

            describe 'remove and re-add the user' do
              before do
                post :create, @parameters
                member = Member.last
                member.deactivate
              end

              pending "no confirmation" do
                it "re-sends the confirmation email" do
                  message = double
                  message.should_receive(:deliver)
                  Devise.mailer.should_receive(:confirmation_instructions).and_return(message)
                  post :create, @parameters
                end
              end
              
              pending "this fails and I don't know why" do
                it "does send the re-activation email" do
                  UserMailer.should_receive(:notify_reactivated)
                  post :create, @parameters
                end
              end
            end

            describe 'missing role_name' do
              before do
                @parameters["member"]['role_name'] = nil
              end

              it "does not change the member count" do
                expect { post :create, @parameters }.to_not change { Member.count }
              end

              it "puts up a flash message" do
                pending "standardize handling of flash messages"
                post :create, @parameters
                flash[:error].should =~ /role name/i
              end
            end
          end

          def confirm_create_sends_email mail_method, parameters
            message = double
            message.should_receive(:deliver)
            UserMailer.should_receive(mail_method).and_return(message)
            post :create, parameters
          end

          context 'create member for existing user' do

            before do
              @parameters["user"]["email"] = Factory(:confirmed_user).email
            end

            it "creates a new member record" do
              expect { post :create, @parameters }.to change {
                @project.reload.members.count
              }.by(1)
            end

            it "sends an email notice" do
              confirm_create_sends_email :confirm_add_to_project, @parameters
            end

            it "cannot add a user to a project if he is already on the project" do
              @parameters["user"]["email"] = @user.email
              expect { post :create, @parameters }.to_not change { Member.count }
            end

            it "does not create a UserActivity record" do
              expect { post :create, @parameters }.should_not change(UserActivity, :count)
            end

            describe 'missing role_name' do
              before do
                @parameters["member"]['role_name'] = nil
              end

              it "does not change the member count" do
                expect { post :create, @parameters }.to_not change { Member.count }
              end

              it "puts up a flash message" do
                pending "standardize handling of flash messages"
                post :create, @parameters
                flash[:error].should =~ /role name/i
              end
            end
          end

          describe "re-activating a user" do
            before do
              @inactive_member = Factory(:member_who_has_joined_project, :project => @project, :activated => false, :level => 'Normal')
              @parameters["user"]["email"] = @inactive_member.user.email
            end

            it "does not create a new member object" do
              expect { post :create, @parameters }.to_not change { Member.count }
            end

            it "changes the 'activated' flag on the existing member record" do
              post :create, @parameters
              @inactive_member.reload.should be_activated
            end

            it "updates the re-activated user's level from param values" do
              post :create, @parameters
              @inactive_member.reload.level.should == 'Viewer'
            end

            it "sends an email notice" do
              confirm_create_sends_email :notify_reactivated, @parameters
            end

            describe 'missing role_name' do
              before do
                @parameters["member"]['role_name'] = nil
              end

              it "does not change the member count" do
                expect { post :create, @parameters }.to_not change { Member.count }
              end

              it "puts up a flash message" do
                post :create, @parameters
                flash[:error].should =~ /role name/i
              end
            end
          end
        end
      end

      context 'user is not a member of the project' do
        context "user is not related to the project at all" do
          it 'redirects to the root page' do
            owner = Factory(:owner, :user => @user)
            post :create, "project_id" => @project.id
            response.should redirect_to current_user_path
          end
        end

        context "the user has not joined the project" do
          it 'redirects to the root page' do
            member = Factory(:member, :project => @project, :user => @user, :level => 'Viewer')
            post :create, "project_id" => @project.id
            response.should redirect_to current_user_path
          end
        end

        context "the user has been deactivated" do
          it 'redirects to the root page' do
            member = Factory(:member_who_has_joined_project, :project => @project, :user => @user, :level => 'Viewer')
            member.deactivate
            post :create, "project_id" => @project.id
            response.should redirect_to current_user_path
          end
        end
      end
    end
  end

  describe "PUT update" do

    before do
      @owner = Factory(:owner)
      @project = @owner.project
      @member_being_changed = Factory(:member_who_has_joined_project, :project => @project, :level => "Viewer")
    end

    context 'no signed in user' do
      it 'should not create the member' do
        put :update, {
            "project_id" => @project.id, "id" => @member_being_changed.id,
            "member" => {"level" => 'Normal', "role_name" => "Other"}}
        @member_being_changed.reload.level.should == 'Viewer'
      end
    end

    context 'signed in user' do
      before do
        request.env["devise.mapping"] = Devise.mappings[:user]
        @user = Factory(:confirmed_user)
        sign_in @user
      end

      context 'is member of project' do

        describe 'level restrictions' do
          %w(Normal Viewer).each do |level|
            it "DOES NOT change the level when current_user is #{level}" do
              Factory(:member_who_has_joined_project, :user => @user, :project => @project, :level => level)
              put :update, {
                  "project_id" => @project.id, "id" => @member_being_changed.id,
                  "member" => {"level" => 'Normal', "role_name" => "Other"}}
              @member_being_changed.reload.level.should == 'Viewer'
            end
          end
        end

        describe 'business logic' do
          before do
            @owner.user = @user
            @owner.save!
            @project.reload
          end

          it "changes the level" do
            put :update, {"project_id" => @project.id, "id" => @member_being_changed.id, "member" => {"level" => 'Normal', "role_name" => "Other"}}
            @member_being_changed.reload.level.should == 'Normal'
          end
        end
      end

      context 'user is not a member of the project' do
        it 'should not update the member' do
          put :update, {
              "project_id" => @project.id, "id" => @member_being_changed.id,
              "member" => {"level" => 'Normal'}}
          @member_being_changed.reload.level.should == 'Viewer'
        end
      end
    end

    context "current_user is Admin" do
      before do
        @user_making_change = Factory(:member, :user => @user, :level => 'Admin', :project => Factory(:project))
        @project = @user_making_change.project
        @member_being_changed = Factory(:member, :project => @project, :level => 'Viewer')
      end
    end
  end

  describe "GET join" do
    before do
      owner = Factory(:owner)
      @new_member = Factory(:member_with_confirmed_user, :project => owner.project)
    end

    context "join_code expectations" do
      it "confirms a user has joined a project" do
        @new_member.join_code.should_not be_nil
        pending "no confirmation" do
          get :join_project, "join_code" => @new_member.join_code
          @new_member.reload.join_code.should be_nil
        end
      end

      pending "no confirmation" do
        it "rejects an invalid join_code" do
          get :join_project, "join_code" => "this is a join code that won't be found in the DB"
          @new_member.reload.should_not be_nil
        end
      end
    end

    context "redirects to" do
      it "project home page if joined user logged in" do
        sign_in @new_member.user
        pending "no confirmation" do
          get :join_project, "join_code" => @new_member.join_code
        end
        response.should redirect_to(project_path(@new_member.project_id))
      end

      pending "no confirmation" do
        it "user page if the join code is invalid but the user is already signed in" do
          sign_in @new_member.user
          get :join_project, "join_code" => "this is a join code that won't be found in the DB"
          response.should redirect_to(current_user_path)
        end
      end

      pending "no confirmation" do
        it "login page if the join code is valid and the user is not signed in" do
          get :join_project, "join_code" => @new_member.join_code
          response.should redirect_to(new_user_session_path)
        end
      end
      
      pending "no confirmation" do
        it "login page if the join code is invalid and the user is not signed in" do
          @new_member.update_attribute(:join_code, "this is a join code that won't be found in the DB")
          get :join_project, "join_code" => @new_member.join_code
          response.should redirect_to(new_user_session_path)
        end
      end
    end
  end

  pending "no confirmation" do
    describe "GET resend_invitation" do
      before do
        request.env["devise.mapping"] = Devise.mappings[:user]
        @user = Factory(:confirmed_user)
        sign_in @user

        @message = double
        @owner = Factory(:owner)
        @project = @owner.project
        @member = Factory(:member, :project => @project)
      end

      context 'user is member of project' do
        before do
          @owner.user = @user
          @owner.save!
          @project.reload
        end

        context "member has not yet accepted the original email from Devise" do
          it "should not send another 'join_code' email" do
            UserMailer.should_not_receive(:confirm_add_to_project)
            get :resend_invitation, "member_id" => @member.id
          end
          it "sends another Devise email" do
            @message.should_receive(:deliver)
            Devise.mailer.should_receive(:confirmation_instructions).and_return(@message)
            get :resend_invitation, "member_id" => @member.id
          end
        end

        context "User was already confirmed (on another project), but has not accepted the 'join project' email" do
          it "should not send another Devise email" do
            # Devise handles this case and so we don't need to test it
          end
          it "sends another email having the same join code as the original email" do
            @member.user.confirm!
            original_join_code = @member.join_code
            @message.should_receive(:deliver)
            UserMailer.should_receive(:confirm_add_to_project).and_return(@message)
            get :resend_invitation, "member_id" => @member.id
            @member.reload.join_code.should == original_join_code
          end
        end
      end

      context 'user is not a member of the project' do
        context "User was already confirmed (on another project), but has not accepted the 'join project' email" do
          it 'should redirect to user path' do
            @member.user.confirm!
            UserMailer.should_not_receive(:confirm_add_to_project)
            get :resend_invitation, "member_id" => @member.id
          end
        end
      end
    end
  end
end
