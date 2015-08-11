require 'spec_helper'

describe BlogPostsController do

  describe "#show" do
    #TODO add some tests
  end

  describe "#new" do

    context 'LeanLaunchLab project' do
      before do
        project = create_lll_project
        @owner = project.members.first
        sign_in @owner.user
      end

      after do
        sign_out @owner.user
      end

      it 'does not assign LLL in the projects if member is Normal' do
        @owner.update_attribute(:level, 'Normal')
        get :new, :project_id => @owner.project_id
        response.should be_redirect
      end

      it 'assigns LLL in the projects' do
        get :new, :project_id => @owner.project_id
        assigns[:projects].should include @owner.project
      end

    end

    context 'project other than LeanLaunchLab' do

      before do
        @owner = Factory(:owner)
      end

      context 'authenticated user who is a member of the project' do
        before do
          sign_in @owner.user
        end

        it 'should render new' do
          get :new, :project_id => @owner.project_id
          response.should render_template("new")
        end

        it 'assigns @blog_post' do
          pending "do this once we deliver NSF"
          # TODO:  essentially, don't we need coverage for this line of code:
          # @blog_post.post_items.build (from the controller)
        end

        it 'assigns key learnings' do
          get :new, :project_id => @owner.project_id
          assigns[:learnings].should == ""
        end

        it 'assigns projects' do
          get :new, :project_id => @owner.project_id
          assigns[:projects].should_not be_nil
          assigns[:projects].first.should be_kind_of(Project)
        end

        it 'assigns project' do
          get :new, :project_id => @owner.project_id
          assigns[:project].should == @owner.project
        end

        it 'assigns no_project' do
          get :new, :project_id => @owner.project_id
          assigns[:no_project].should be_false
          get :new, :project_id => @owner.project_id, :all_projects => 'true'
          assigns[:no_project].should be_true
        end

        it "assigns 'associated_file_ids' as a session variable" do
          get :new, :project_id => @owner.project_id

          session[:associated_file_ids].should == []
        end
      end

      context 'authenticated user who has been invited to the project, but has not joined' do

        before do
          member = Factory(:member_with_confirmed_user, :project => @owner.project)
          sign_in member.user
        end

        it 'should redirect to the user page' do
          get :new, :project_id => @owner.project_id
          response.should redirect_to current_user_path
        end
      end

      context 'authenticated user who was a member of the project but was deactivated' do

        before do
          member = Factory(:member_with_confirmed_user, :project => @owner.project)
          member.deactivate
          sign_in member.user
        end

        it 'should redirect to the user page' do
          get :new, :project_id => @owner.project_id
          response.should redirect_to current_user_path
        end
      end

      context 'authenticated user who is NOT a member of the project' do

        before do
          sign_in @owner.user
        end

        it 'should redirect to the user page' do
          owner2 = Factory(:owner)
          get :new, :project_id => owner2.project_id
          response.should redirect_to current_user_path
        end
      end

      context 'un-authenticated user' do
        it 'should redirect to the login screen' do
          get :new, :project_id => @owner.project_id
          response.should redirect_to new_user_session_path
        end
      end
    end
  end

  describe "save_draft" do
    before do
      @owner = Factory(:owner)
      @parameters = {"blog_post" => {"subject" => "My test blog post", "body" => "this is a short blog post", "the_ask" => "Just FYI"},
                     "project_id" => @owner.project_id, :draft => '1'}
    end

    context 'authenticated user who is a member of the project' do

      context "level is admin" do
        before do
          sign_in @owner.user
        end

        it "saves a blog_post draft with valid params" do
          expect { post :create, @parameters }.should change { BlogPost.draft.count }.by(1)
        end

        it "saves a blog_post draft with minimal (invalid) params" do
          expect { post :create, {:draft => '1', "project_id" => @owner.project_id} }.should change { BlogPost.draft.count }.by(1)
        end

        ['body', 'the_ask', 'subject'].each do |attr|
          it "saves with just draft, project_id and #{attr}" do
            post :create, {:draft => '1', "project_id" => @owner.project_id, attr => 'TEST'}
            BlogPost.last[attr].should == 'TEST'
          end
        end

        it "keeps published_at nil" do
          post :create, {"project_id" => @owner.project_id, :draft => '1'}
          BlogPost.last.should be_present
          BlogPost.last.published_at.should be_nil
        end
      end
    end
  end

  describe "#create" do

    before do
      @owner = Factory(:owner)
      @parameters = {"blog_post" => {"subject" => "My test blog post", "body" => "this is a short blog post", "the_ask" => "Just FYI"},
                     "project_id" => @owner.project_id}
    end

    context 'authenticated user who is a member of the project' do

      context "level is admin" do
        before do
          sign_in @owner.user
        end

        it "should create a new BlogPost" do
          expect { post :create, @parameters }.should change { BlogPost.count }.by(1)
        end

        it "sets published_at" do
          post :create, @parameters
          BlogPost.last.published_at.to_i.should be_present
          BlogPost.last.published_at.to_i.should be_within(5).of(Time.now.to_i)
          BlogPost.last.date.should == BlogPost.last.published_at.in_time_zone("Pacific Time (US & Canada)").to_date
        end

        it "creates a PostItem if nested attributes passed for it" do
          canvas_item = Factory(:canvas_item, :project => @owner.project)
          canvas_item2 = Factory(:canvas_item, :project => @owner.project)
          @parameters["blog_post"][:post_items_attributes] = {"0" => {:canvas_item_id => canvas_item.id},
                                                              "1" => {:canvas_item_id => canvas_item2.id}}
          expect { post :create, @parameters }.should change { PostItem.count }.by(2)
        end

        it "creates a UserActivity record" do
          expect { post :create, @parameters }.should change(UserActivity, :count).by(1)
          blog_post = BlogPost.last
          user_activity = UserActivity.last
          user_activity.description.should == "#{@owner.user.name} created blog post in #{@owner.project.name}"
          user_activity.action.should == "Create blog post"
          user_activity.member.should == @owner
        end

        it 'should print flash message on success' do
          post :create, @parameters
          flash[:notice].should == "Blog post created successfully"
        end

        it 'should redirect to project page' do
          post :create, @parameters
          response.should redirect_to project_path(@owner.project)
        end

        it 'should create learnings from the learnings param' do
          params = @parameters.merge(:learnings => "Learning 1\r\n Learning 2")
          expect { post :create, params }.should change { Learning.count }.by(2)
        end

        it "assigns the id of the blog post into the 'assetable_id' column of the picture model (ckeditor_assets table)" do
          picture = Factory(:picture)
          session[:associated_file_ids] = [picture.id]
          post :create, @parameters
          picture.reload
          picture.assetable_id.should == BlogPost.last.id
          picture.assetable_type.should == "BlogPost"
        end
      end

      context "level is Normal" do
        before do
          member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Normal")
          sign_in member.user
        end

        it "Normal level members should create a new BlogPost" do
          expect { post :create, @parameters }.should change { BlogPost.count }.by(1)
        end
      end

      context "level is Viewer" do
        before do
          member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => 'Viewer')
          sign_in member.user
        end

        it "should NOT create a new BlogPost" do
          expect { post :create, @parameters }.should_not change { BlogPost.count }
        end
      end

      context 'authenticated user who is NOT a member of the project' do
        it 'should redirect to the user page' do
          sign_in @owner.user
          someone_elses_project = Factory(:project)
          parameters = {"blog_post" => {"subject" => "My test blog post", "body" => "this is a short blog post"}, "project_id" => someone_elses_project.id}
          post :create, parameters
          response.should redirect_to current_user_path
        end
      end

      context 'un-authenticated user' do
        it 'should redirect to the login screen' do
          post :create, @parameters
          response.should redirect_to new_user_session_path
        end
      end

    end
  end

  describe "#edit" do

    before do
      @owner = Factory(:owner)
      @blog_post = Factory(:blog_post, :member => @owner)
      @project = @owner.project
    end

    context 'authenticated user who is a member of the project' do
      before do
        sign_in @owner.user
      end

      it 'should render edit' do
        get :edit, :project_id => @project.id, :id => @blog_post.id
        response.should render_template("edit")
      end

      it 'should not render edit for a blog post that does not belong to this project' do
        owner2 = Factory(:owner)
        blog_post2 = Factory(:blog_post, :member => owner2)
        get :edit, :project_id => @project.id, :id => blog_post2.id
        response.should_not render_template("edit")
      end

      it 'assigns key learnings' do
        learning1 = Factory(:learning, :blog_post => @blog_post, :content => "People like turtles")
        learning2 = Factory(:learning, :blog_post => @blog_post, :content => "People really like turtles")
        get :edit, :project_id => @project.id, :id => @blog_post.id

        assigns[:learnings].should == "People like turtles\r\nPeople really like turtles"
      end

      it 'assigns project' do
        get :edit, :project_id => @project.id, :id => @blog_post.id
        assigns[:project].should == @project
      end

      it 'assigns projects' do
        get :edit, :project_id => @project.id, :id => @blog_post.id
        assigns[:projects].should_not be_nil
        assigns[:projects].first.should be_kind_of(Project)
      end

      it 'assigns all_projects' do
        get :edit, :project_id => @owner.project_id, :id => @blog_post.id
        assigns[:no_project].should be_false
        get :edit, :project_id => @owner.project_id, :id => @blog_post.id, :all_projects => 'true'
        assigns[:no_project].should be_true
      end

      it "assigns 'associated_file_ids' as a session variable" do
        get :new, :project_id => @owner.project_id

        session[:associated_file_ids].should == []
      end
    end

    context 'authenticated user who has been invited to the project, but has not joined' do

      before do
        member = Factory(:member_with_confirmed_user, :project => @owner.project)
        sign_in member.user
      end

      it 'should redirect to the user page' do
        get :edit, :project_id => @project.id, :id => @blog_post.id
        response.should redirect_to current_user_path
      end
    end

    context 'authenticated user who was a member of the project but was deactivated' do

      before do
        member = Factory(:member_with_confirmed_user, :project => @owner.project)
        member.deactivate
        sign_in member.user
      end

      it 'should redirect to the user page' do
        get :edit, :project_id => @project.id, :id => @blog_post.id
        response.should redirect_to current_user_path
      end
    end

    context 'authenticated user who is NOT a member of the project' do

      before do
        sign_in @owner.user
      end

      it 'should redirect to the user page' do
        owner2 = Factory(:owner)
        blog_post2 = Factory(:blog_post, :member => owner2)
        get :edit, :project_id => owner2.project.id, :id => blog_post2.id
        response.should redirect_to current_user_path
      end
    end

    context 'un-authenticated user' do
      it 'should redirect to the login screen' do
        get :edit, :project_id => @project.id, :id => @blog_post.id
        response.should redirect_to new_user_session_path
      end
    end

  end

  describe "#update" do

    before do
      @owner = Factory(:owner)
      @blog_post = Factory(:blog_post, :member => @owner)
      @parameters = {"blog_post" => {"subject" => "My updated subject", "body" => "updated body"}, "project_id" => @owner.project_id, "id" => @blog_post.id}
    end

    context 'authenticated user who is a member of the project' do

      context "level is Admin" do
        before do
          sign_in @owner.user
        end

        it "should update BlogPost" do
          put :update, @parameters
          @blog_post.reload
          @blog_post.subject.should == @parameters['blog_post']['subject']
          @blog_post.body.should == @parameters['blog_post']['body']
        end

        it "does not increase count of associated canvas items when params contain already associated items" do
          canvas_item = Factory(:canvas_item)
          @parameters["blog_post"][:post_items_attributes] = {"0" => {:canvas_item_id => canvas_item.id}}
          put :update, @parameters
          put :update, @parameters
          @blog_post.reload
          @blog_post.post_items.count.should == 1
        end

        it 'should not update a blog post that does not belong to this project' do
          owner2 = Factory(:owner)
          blog_post2 = Factory(:blog_post, :member => owner2)
          parameters = {"blog_post" => {"subject" => "My updated subject", "body" => "updated body", "project_id" => @owner.project_id}, "project_id" => @owner.project_id, "id" => blog_post2.id}
          put :update, parameters
          blog_post2.reload
          blog_post2.subject.should_not == parameters['blog_post']['subject']
          blog_post2.body.should_not == parameters['blog_post']['body']
        end

        it "assigns the id of the blog post into the 'assetable_id' column of the picture model (ckeditor_assets table)" do
          picture = Factory(:picture)
          session[:associated_file_ids] = [picture.id]
          put :update, @parameters
          picture.reload
          picture.assetable_id.should == BlogPost.last.id
          picture.assetable_type.should == "BlogPost"
        end

        describe "updating drafts" do
          before { @blog_post.update_attribute(:published_at, nil) }

          ['subject', 'body'].each do |key|
            it "updates with required param #{key} missing if draft" do
              @parameters['blog_post'][key] = nil
              @parameters['draft'] = 1
              put :update, @parameters
              @blog_post.reload
              @blog_post[key].should be_nil
            end
          end
        end

        describe "publishing" do
          before do
            #make a member to receive mail
            Factory(:member_who_has_joined_project, :project => @owner.project, :level => 'Admin')
          end

          it "sends an email when publishing a draft" do
            @blog_post.update_attribute(:published_at, nil)
            message = double
            message.should_receive(:deliver)
            BlogPostMailer.should_receive(:mail_contents_of_blog_post).and_return(message)
            put :update, @parameters
          end

          it "does not send email when updating an already published blog post" do
            BlogPostMailer.should_not_receive(:mail_contents_of_blog_post)
            put :update, @parameters
          end
        end
      end

      context "permission level Normal" do
        before do
          member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => "Normal")
          sign_in member.user
        end

        it "level of Normal should update a BlogPost" do
          put :update, @parameters
          @blog_post.reload
          @blog_post.subject.should == @parameters['blog_post']['subject']
          @blog_post.body.should == @parameters['blog_post']['body']
        end
      end

      context "permission level Viewer" do
        before do
          member = Factory(:member_who_has_joined_project, :project => @owner.project, :level => 'Viewer')
          sign_in member.user
        end

        it "should NOT update a BlogPost" do
          put :update, @parameters
          @blog_post.reload
          @blog_post.subject.should_not == @parameters['blog_post']['subject']
          @blog_post.body.should_not == @parameters['blog_post']['body']
        end
      end
      context 'authenticated user who is NOT a member of the project' do
        it 'should redirect to the user page' do
          sign_in @owner.user
          owner2 = Factory(:owner)
          blog_post2 = Factory(:blog_post, :member => owner2)
          parameters = {"blog_post" => {"subject" => "My test blog post", "body" => "this is a short blog post"}, "project_id" => owner2.project.id, "id" => blog_post2.id}

          put :update, parameters
          response.should redirect_to current_user_path
        end
      end

      context 'un-authenticated user' do
        it 'should redirect to the login screen' do
          put :update, @parameters
          response.should redirect_to new_user_session_path
        end
      end

    end
  end

  describe "#delete" do
    before do
      @user = Factory(:confirmed_user)
    end

    context 'authenticated user' do

      before do
        sign_in @user
      end

      context 'user is member of project' do

        def setup_member_and_project level
          owner = Factory(:owner)
          member = Factory(:member_who_has_joined_project, :project => owner.project, :user => @user, :level => level)
          @project = member.project
          @member = member
        end

        describe 'permission level restriction' do
          %w(Admin Normal Viewer).each do |level|
            context "level is #{level}" do
              before do
                setup_member_and_project(level)
                @blog_post = Factory(:blog_post, :member => @member)
                @params = {:project_id => @project.id, :id => @blog_post.id}
              end

              if level == "Viewer"
                it 'should NOT delete the blog post' do
                  expect { delete :destroy, @params }.should_not change(BlogPost, :count)
                end

                it 'should redirect to the user page' do
                  delete :destroy, @params
                  response.should redirect_to current_user_path
                end
              else
                it 'should delete the blog post' do
                  expect { delete :destroy, @params }.should change(BlogPost, :count).by(-1)
                end

                it 'should redirect to the project page' do
                  delete :destroy, @params
                  response.should redirect_to project_path(@project)
                end
                it 'should set a flash message' do
                  delete :destroy, @params
                  flash[:notice].should =~ /deleted successfully/
                end
                it 'should not delete a blog post that does not belong to this project' do
                  blog_post2 = Factory(:blog_post)
                  delete :destroy, {:project_id => @project.id, :id => blog_post2.id}
                  expect { delete :destroy, @params }.should_not change(BlogPost, :count)
                  response.should redirect_to current_user_path
                end
              end
            end
          end
        end
      end

      context 'user is NOT member of project' do
        it 'should not delete' do
          owner2 = Factory(:owner)
          blog_post2 = Factory(:blog_post, :member => owner2)
          params = {:project_id => blog_post2.project.id, :id => blog_post2.id}
          expect { delete :destroy, params }.should_not change(BlogPost, :count)
          response.should redirect_to current_user_path
        end
      end
    end

    context 'un-authenticated user' do
      it 'should redirect to the login screen' do
        owner2 = Factory(:owner)
        blog_post2 = Factory(:blog_post, :member => owner2)
        params = {:project_id => blog_post2.project.id, :id => blog_post2.id}
        delete :destroy, params
        response.should redirect_to new_user_session_path
      end
    end
  end
end
