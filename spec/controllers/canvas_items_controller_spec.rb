require 'spec_helper'

describe CanvasItemsController do
  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET new" do

    before do
      @owner = Factory(:owner)
      @project = @owner.project
      @box = Box.first
    end

    context 'un-authenticated user' do
      it 'redirects to the login screen' do
        get :new, :project_id => @project.id, :box_name => @box.name
        response.should redirect_to new_user_session_path
      end
    end

    context 'authenticated user who is a member of the project' do

      before do
        sign_in @owner.user
      end

      it 'is successful' do
        get :new, :project_id => @project.id, :box_name => @box.name
        response.should be_success
      end

      it 'should have references to the Project and Box' do
        get :new, :project_id => @project.id, :box_name => @box.name
        assigns[:project].should == @project
        assigns[:box].should == @box
      end

      it 'has a reference to a canvas_item' do
        get :new, :project_id => @project.id, :box_name => @box.name
        assigns[:canvas_item].should be_kind_of(CanvasItem)
        assigns[:canvas_item].should be_new_record
      end
    end

    context 'authenticated user who is NOT a member of the project' do

      before do
        sign_in @owner.user
      end

      it 'redirects to the user page' do
        owner2 = Factory(:owner)
        get :new, :project_id => owner2.project_id, :box_name => @box.name
        response.should redirect_to current_user_path
      end

    end
  end

  describe "POST create" do

    before do
      @owner = Factory(:owner)
      @project = @owner.project
      @box = Box.first
      @parameters = {"canvas_item"=>{"text"=>"qwerasdf", "project_id"=>@project.id, "box_id"=>@box.id}, :format => :json}
    end

    context 'un-authenticated user' do
      it 'redirects to the login screen' do
        @parameters = {"canvas_item"=>{"text"=>"qwerasdf", "project_id"=>@project.id, "box_id"=>@box.id}}
        post :create, @parameters
        response.should redirect_to new_user_session_path
      end
    end

    context 'authenticated user who is a member of the project' do

      context "abilities unique to Admin" do
        before do
          sign_in @owner.user
        end

        it 'should return json response to create request' do
          post :create, @parameters
          response.headers['Content-Type'].should =~ /json/
          response.should_not be_redirect
        end

        it "creates new canvas item with ajax" do
          expect { post :create, @parameters }.should change { CanvasItem.count }.by(1)
        end

        it "won't create a badly formed canvas item" do
          @parameters["canvas_item"]["text"] = ''
          expect { post :create, @parameters }.should_not change { CanvasItem.count }
          response.status.should == 403
        end

        it "creates a UserActivity record" do
          expect { post :create, @parameters }.should change(UserActivity, :count).by(1)
          canvas_item = CanvasItem.last
          user_activity = UserActivity.last
          user_activity.description.should == "#{@owner.user.name} created canvas item in #{@project.name}"
          user_activity.action.should == "Create canvas item"
          user_activity.member.should == @owner
        end
      end

      %w(Admin Normal).each do |level|
        context "permission level is #{level}" do
          before do
            member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => level)
            sign_in member.user
          end

          it "#{level} should create a new CanvasItem" do
            expect { post :create, @parameters }.should change { CanvasItem.count }.by(1)
          end
        end
      end

      context "permission level is viewer" do
        before do
          member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => 'Viewer')
          sign_in member.user
        end

        it "does NOT create a new CanvasItem" do
          expect { post :create, @parameters }.should_not change { CanvasItem.count }
        end
      end
    end

    context 'authenticated user who is NOT a member of the project' do
      it 'does not add a canvas item' do
        sign_in @owner.user
        someone_elses_project = Factory(:project)
        parameters = {"canvas_item"=>{"text"=>"qwerasdf", "project_id"=>someone_elses_project.id, "box_id"=>@box.id}, :format => :json}
        post :create, parameters
        expect { post :create, @parameters }.should_not change { CanvasItem.count }
      end
    end

  end

  describe "GET edit" do
    context "un-authenticated user" do
      it "redirects to the login screen" do
        get :edit, :id => 1
        response.should redirect_to new_user_session_path
      end
    end

    context "authenticated user" do
      before do
        @owner = Factory(:owner)
        sign_in @owner.user
      end

      context "who is a member with sufficient status on the project (e.g. owner)" do
        before do
          @canvas_item = Factory(:canvas_item, :project => @owner.project)
        end

        it "renders edit" do
          get :edit, :id => @canvas_item.id
          response.should render_template("edit")
        end
      end

      context "level is Viewer" do
        before do
          viewer = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Viewer")
          sign_in viewer.user
          @canvas_item = Factory(:canvas_item, :project => @owner.project)
        end

        it "redirects to the user page" do
          get :edit, :id => @canvas_item.id
          response.should redirect_to current_user_path
        end
      end

      pending "no confirmation" do
        context "level is Admin, but has not joined" do
          before do
            admin = Factory(:member_with_confirmed_user, :project => @owner.project, :level => "Admin")
            sign_in admin.user
            @canvas_item = Factory(:canvas_item, :project => @owner.project)
          end

          it "redirects to the user page" do
            get :edit, :id => @canvas_item.id
            response.should redirect_to current_user_path
          end
        end
      end
      
      context "level is admin but has been deactivated" do
        before do
          admin = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Admin")
          admin.deactivate
          sign_in admin.user
          @canvas_item = Factory(:canvas_item, :project => @owner.project)
        end

        it "redirects to the user page" do
          get :edit, :id => @canvas_item.id
          response.should redirect_to current_user_path
        end
      end

      context "NOT a member of the project" do
        before do
          @canvas_item = Factory(:canvas_item)
          get :edit, :id => @canvas_item.id
        end

        it "redirects to the user page" do
          get :edit, :id => @canvas_item.id
          response.should redirect_to current_user_path
        end
      end
    end
  end

  describe "PUT update" do

    context "un-authenticated user" do
      it "redirects to the login screen" do
        get :update, :id => 1
        response.should redirect_to new_user_session_path
      end
    end

    context "authenticated user" do
      before do
        @owner = Factory(:owner)
        @canvas_item = Factory(:canvas_item, :text => 'old worn out text', :project => @owner.project)
        sign_in @owner.user
      end

      context "abilities unique to Admin" do
        describe 'update data' do
          it "creates a new item with the same original_id and updated attributes" do
            expect { put :update, :id => @canvas_item.id,
                         :canvas_item => {:text => 'new improved text'}, :format => :json }.to change { CanvasItem.count }.by(1)

            new_canvas_item = CanvasItem.last
            new_canvas_item.text.should == 'new improved text'
            new_canvas_item.original_id.should == @canvas_item.original_id
            new_canvas_item.created_at.should_not == @canvas_item.created_at
            new_canvas_item.updated_at.should_not == @canvas_item.updated_at
            new_canvas_item.id.should_not == @canvas_item.id
          end

          it 'should not update the attributes of the original canvas item except inactive_at' do
            orig_attrs = @canvas_item.attributes
            put :update, :id => @canvas_item.id,
                :canvas_item => {:text => 'new improved text'}, :format => :json
            @canvas_item.reload
            attrs = @canvas_item.attributes
            inactive_at = attrs.delete("inactive_at")
            orig_attrs.delete("inactive_at")
            pending "eql? doesn't seem to work?!" do
              attrs.should eql(orig_attrs)
            end
            inactive_at.should_not be_nil
          end

          it "can't update items of a project the owner is not a member of" do
            owner2 = Factory(:owner)
            canvas_item2 = Factory(:canvas_item, :text => 'old worn out text', :project => owner2.project)
            expect { put :update, :id => canvas_item2.id,
                         :canvas_item => {:text => 'new improved text', :project_id => @owner.project.id}, :format => :json }.to_not change { CanvasItem.count }
          end

          it "won't save a badly formed canvas item" do
            expect { put :update, :id => @canvas_item.id,
                         :canvas_item => {:text => ''}, :format => :json }.to_not change { CanvasItem.count }
            response.status.should == 403
          end

          it "does not redirect" do
            put :update, :id => @canvas_item.id, :canvas_item => {:text => 'new improved text'}, :format => :json
            response.should_not be_redirect
          end
        end

        describe 'update status (ajax calls)' do
          it "updates a status" do
            expect { put :update, :id => @canvas_item.id, :canvas_item => {:item_status_id => ItemStatus[:invalid]}, :format => :json }.to change { CanvasItem.count }.by(1)
            CanvasItem.last.item_status_id.should == ItemStatus[:invalid]
            response.body.should == {:id => CanvasItem.last.id}.to_json
          end
        end
      end

      %w(Admin Normal).each do |level|
        context "level is #{level}" do
          before do
            member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => level)
            sign_in member.user
          end

          it "updates an item" do
            expect { put :update, :id => @canvas_item.id, :canvas_item => {:text => 'new improved text'}, :format => :json }.to change { CanvasItem.count }.by(1)
            CanvasItem.last.text.should == 'new improved text'
          end

          it "does not redirect" do
            put :update, :id => @canvas_item.id, :canvas_item => {:text => 'new improved text'}, :format => :json
            response.should_not be_redirect
          end
        end
      end

      context "level is Viewer" do
        before do
          viewer = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Viewer")
          sign_in viewer.user
        end

        it "redirects to the user page" do
          put :update, :id => @canvas_item.id, :canvas_item => {:text => 'new improved text'}, :format => :json
          response.should redirect_to current_user_path
        end
      end

      pending "no confirmation" do
        context "level is Admin, but has not joined" do
          before do
            admin = Factory(:member_with_confirmed_user, :project => @owner.project, :level => "Admin")
            sign_in admin.user
          end

          it "redirects to the user page" do
            put :update, :id => @canvas_item.id, :canvas_item => {:text => 'new improved text'}, :format => :json
            response.should redirect_to current_user_path
          end
        end
      end
      
      context "level is Admin but has been deactivated" do
        before do
          admin = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Admin")
          admin.deactivate
          sign_in admin.user
        end

        it "redirects to the user page" do
          put :update, :id => @canvas_item.id, :canvas_item => {:text => 'new improved text'}, :format => :json
          response.should redirect_to current_user_path
        end
      end

      context "NOT a member of the project" do
        before do
          @canvas_item = Factory(:canvas_item)
        end

        it "redirects to the user page" do
          put :update, :id => @canvas_item.id, :canvas_item => {:text => 'new improved text'}, :format => :json
          response.should redirect_to current_user_path
        end
      end
    end

  end

  describe "DELETE destroy" do
    before do
      @owner = Factory(:owner)
      @project = @owner.project
      @item = Factory(:canvas_item, :project => @project)
      @params = {:id => @item.id, :format => :json}
    end

    context 'un-authenticated user' do
      it 'redirect to the login screen' do
        expect { delete :destroy, @params }.to_not change { CanvasItem.count }
        response.should_not be_redirect
      end
    end

    context 'authenticated user who is a member of the project' do
      context "abilities unique to Admin" do
        before do
          sign_in @owner.user
        end

        it "creates a new copy and marks it deleted" do
          expect { delete :destroy, @params }.to change { CanvasItem.count }.by(1)
          CanvasItem.last.deleted?.should be_true
        end

        it 'reloads the project page after delete' do
          delete :destroy, @params
          response.should_not be_redirect
        end

      end

      %w(Admin Normal).each do |level|
        context "level is #{level}" do
          before do
            member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => level)
            sign_in member.user
          end

          it "creates a new copy and marks it deleted" do
            expect { delete :destroy, @params }.to change { CanvasItem.count }.by(1)
            CanvasItem.last.deleted?.should be_true
          end
        end
      end

      context "level is Viewer" do
        before do
          member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => 'Viewer')
          sign_in member.user
        end

        it "can not delete the item" do
          expect { delete :destroy, @params }.to_not change { CanvasItem.count }
        end
      end

      context "level is Admin but has been deactivated" do
        before do
          member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Admin")
          member.deactivate
          sign_in member.user
        end

        it "can not delete the item" do
          expect { delete :destroy, @params }.to_not change { CanvasItem.count }
        end
      end

      pending "no confirmation" do
        context "level is Admin but has not joined" do
          before do
            member = Factory(:member_with_confirmed_user, :project => @owner.project, :level => "Admin")
            sign_in member.user
          end

          it "can not delete the item" do
            expect { delete :destroy, @params }.to_not change { CanvasItem.count }
          end
        end
      end
    end

    context 'authenticated user who is NOT a member of the project' do
      it 'does not delete the canvas item' do
        sign_in @owner.user
        someone_elses_project = Factory(:project)
        item = Factory(:canvas_item, :project => someone_elses_project)
        params = {:id => item.id, :format => :json}
        expect { delete :destroy, params }.to_not change { CanvasItem.count }
        response.should redirect_to current_user_path
      end
    end

  end

end
