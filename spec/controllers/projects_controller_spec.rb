require 'spec_helper'

describe ProjectsController do

  describe "without a signed-in user" do #TODO dry this up :)
    it "get :show denies access and re-routes to login" do
      get :show, :id => 1
      response.should redirect_to new_user_session_path
    end
    it "get :index denies access and re-routes to login" do
      get :index
      response.should redirect_to new_user_session_path
    end
    it "get :new denies access and re-routes to login" do
      get :new
      response.should redirect_to new_user_session_path
    end
    it "post :create denies access and re-routes to login" do
      post :create, :project => {}
      response.should redirect_to new_user_session_path
    end
  end

  describe "with signed-in user" do

    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = Factory(:confirmed_user)
      sign_in @user
    end

    describe "GET edit" do
      before do
        @owner = Factory(:owner, :user => @user, :level => 'Admin')
        @project = @owner.project
      end

      it "assigns project" do
        get :edit, :id => @project.id
        assigns(:project).should == @project
      end

      it "renders edit page" do
        get :edit, :id => @project.id
        response.should render_template :edit
      end
    end

    describe "PUT update" do
      before do
        @owner = Factory(:owner, :user => @user, :level => 'Admin')
        @project = @owner.project
        @valid_params = Factory.attributes_for(:project, :name => 'Test Project', :url => 'http://www.google.com',
                                               :pitch => 'the pitch')
      end

      describe "with valid params" do
        before { put :update, :id => @project.to_param, :project => @valid_params }

        it "updates the project" do
          @project.reload.name.should == @valid_params[:name]
          @project.url.should == @valid_params[:url]
          @project.pitch.should == @valid_params[:pitch]
        end

        it "redirects to last project" do
          response.should redirect_to(current_user_path)
        end
      end

      describe "url parameter" do
        it "adds https if missing from url" do
          put :update, :id => @project.to_param, :project => @valid_params.merge({:url => 'www.google.com'})
          @project.reload.url.should == 'http://www.google.com'
        end

        it "does not add http if url is blank" do
          put :update, :id => @project.to_param, :project => @valid_params.merge({:url => ''})
          @project.reload.url.should be_empty
        end
      end

      describe "with invalid params" do
        before { put :update, :id => @project.to_param, :project => {:name => ''} }

        it 're-renders the edit page' do
          response.should render_template :edit
        end

        it 'sets a flash error message' do
          flash[:error].should be_present
        end
      end
    end

    describe "GET new_posts" do

      before do
        owner = Factory(:owner, :user => @user)
        @post_writer = Factory(:member_who_has_joined_project, :project => owner.project)
        @post = Factory(:blog_post, :member_id => @post_writer.id)
        10.times { |i| Factory(:user_activity, :user_id => @user.id, :created_at => Time.now.utc - i.minutes) }
        @old_post = Factory(:blog_post, :member => @post_writer, :published_at => Time.now.utc - 1.day)
      end

      describe "assignments" do

        it 'assigns @blog_posts' do
          get :new_posts
          assigns(:blog_posts).first.should == @post
          assigns(:blog_posts).should_not include @old_post
        end

        it "assigns @new_posts_view" do
          get :new_posts
          assigns(:new_posts_view).should be_true
        end

        it "assigns @new_post_count" do
          get :new_posts
          assigns(:new_post_count).should == 1
        end

        it "assigns @new_comments" do
          @comment = Factory(:comment, :blog_post => @old_post, :created_at => Time.now.utc - 2.hours)
          get :new_posts
          assigns(:new_comments).should == [@comment.id]
        end

        it "assigns @posts_to_highlight" do
          get :new_posts
          assigns(:posts_to_highlight).should == [@post.id]
        end

        it "assigns @projects_new_post_counts" do
          @comment = Factory(:comment, :blog_post => @old_post, :created_at => Time.now.utc - 2.hours)
          get :new_posts
          assigns(:projects_new_post_counts)[@post_writer.project_id].should == 2
        end
      end

      it "renders show" do
        get :new_posts
        response.should render_template :show
      end
    end

    describe "GET draft_posts" do

      before do
        @owner = Factory(:owner, :user => @user)
        @post_writer = Factory(:member_who_has_joined_project, :project => @owner.project)
        @someone_elses_draft = Factory(:blog_post, :member_id => @post_writer.id, :published_at => nil)
        @users_draft = Factory(:blog_post, :member_id => @owner.id, :published_at => nil, :subject => "subject 2")
        @old_published_post = Factory(:blog_post, :member => @post_writer, :created_at => Time.now.utc - 1.day)
      end

      describe "assignments" do

        it 'assigns @blog_posts' do
          get :draft_posts
          assigns(:blog_posts).first.should == @users_draft
          assigns(:blog_posts).should_not include @old_published_post
          assigns(:blog_posts).should_not include @someone_elses_draft
        end

        it "assigns @draft_posts_view" do
          get :draft_posts
          assigns(:draft_posts_view).should be_true
        end

        it "assigns @new_post_count" do
          get :draft_posts
          assigns(:new_post_count).should == 1
        end

        it "assigns @new_comments" do
          @comment = Factory(:comment, :blog_post => @old_published_post, :created_at => Time.now.utc - 2.hours)
          get :draft_posts
          assigns(:new_comments).should == []
        end

        it "assigns @posts_to_highlight" do
          get :draft_posts
          assigns(:posts_to_highlight).should == []
        end

        it "assigns @draft_blog_posts in chronological order" do
          3.times {|i| Factory(:blog_post, :member_id => @owner.id, :published_at => nil,
                               :subject => i.to_s, :created_at => Time.now.utc - i.hours)}
          get :draft_posts
          assigns(:draft_blog_posts).map(&:subject).should == ['0', 'subject 2', '1', '2']
        end

        it "assigns @projects_new_post_counts" do
          @comment = Factory(:comment, :blog_post => @old_published_post, :created_at => Time.now.utc - 2.hours)
          get :draft_posts
          assigns(:projects_new_post_counts)[@post_writer.project_id].should == 1
        end
      end

      it "renders show" do
        get :draft_posts
        response.should render_template :show
      end
    end

    describe "GET index" do

      before do
        owner = Factory(:owner, :user => @user)
        post_writer = Factory(:member_who_has_joined_project, :project => owner.project)
        Factory(:blog_post, :member_id => post_writer.id)
        get :index
      end

      describe "assignments" do

        it 'assigns @blog_posts' do
          assigns(:blog_posts).should be_present
          assigns(:blog_posts).first.should be_kind_of(BlogPost)
        end

        it 'assigns @all_projects' do
          assigns(:no_project).should be_true
        end
      end

      it "renders show" do
        response.should render_template :show
      end

      it "stores 'All Projects' in a cookie as 'last_project'" do
        response.cookies['last_project'].should == 'All_Projects'
      end
    end

    describe "GET show" do
      before do
        @project_start = Date.parse('2000-01-31') # this is a Monday
        @project = Factory(:project, :created_at => @project_start, :name => "A")
        @owner = Factory(:owner, :user => @user, :project => @project)
      end

      describe "members list" do
        before do
          @project_user_does_not_own = Factory(:project)
        end

        describe "user is level viewer" do
          before do
            @member = Factory(:member_who_has_joined_project, :project => @project_user_does_not_own, :user => @user,
                              :level => 'Viewer')
            member = Factory(:member_who_has_joined_project, :project => @project_user_does_not_own)
            get :show, :id => @project_user_does_not_own
          end
          it "assigns empty array to members list" do
            assigns[:members].should be_empty
          end
          it "stores last project in a cookie" do
            response.cookies['last_project'].should == @project_user_does_not_own.id.to_s
          end
        end

        describe "user level is Normal" do
          before do
            @member = Factory(:member_who_has_joined_project, :project => @project_user_does_not_own, :user => @user,
                              :level => 'Normal')
          end

          it "includes joined members in members list" do
            member = Factory(:member_who_has_joined_project, :project => @project_user_does_not_own)
            get :show, :id => @project_user_does_not_own
            assigns[:members].should include(member)
          end

          pending "no confirmation" do
            it "does not include unjoined members in members list" do
              member = Factory(:member, :project => @project_user_does_not_own)
              get :show, :id => @project_user_does_not_own
              assigns[:members].should_not include(member)
            end
          end
        end

        describe "user level is Admin" do
          before do
            @member = Factory(:member_who_has_joined_project, :project => @project_user_does_not_own, :user => @user,
                              :level => 'Admin')
          end

          it "includes joined and unjoined members in members list" do
            joined_member = Factory(:member_who_has_joined_project, :project => @project_user_does_not_own)
            un_joined_member = Factory(:member, :project => @project_user_does_not_own)
            get :show, :id => @project_user_does_not_own
            assigns[:members].should include(joined_member)
            assigns[:members].should include(un_joined_member)
          end
        end
      end

      describe "single blog post view" do
        before do
          @specified_post = Factory(:blog_post, :member_id => @owner.id, :project_id => @project.id)
          unspecified_post = Factory(:blog_post, :member_id => @owner.id, :project_id => @project.id)
        end

        it "assigns only that post in blog_posts when blog post specified in URL" do
          pending "can't get this to use the right url'"
          get "/projects/#{@project.id}/blog_post/#{@specified_post.id}"
          assigns(:blog_posts).length.should == 1
          assigns(:blog_posts).first.should == @specified_post
        end

        it "redirects to new route when blog_post_id received as query parameter" do
          #this is needed to support links previously sent in  emails
          get 'show', :id => @project.id, :blog_post_id => @specified_post.id
          response.should redirect_to(projects_blog_post_path(@project, @specified_post))
        end
      end

      pending "this should work" do # FIXME
        context "user has not reset their password" do
          it 'should redirect to the user edit page' do
            @user.update_attribute('has_changed_password', false)
            @user.errors.should be_empty
            get :show, :id => @project.id
            response.should redirect_to(edit_current_user_path)
          end
        end
      end
      
      it "assigns the correct @project" do
        get 'show', :id => @project.id
        assigns(:project).should == @project
      end

      it 'assigns @all_projects' do
        assigns(:all_projects).should be_false
      end

      it "assigns the correct @member, @projects" do
        project_e = Factory(:project, :name => "E")
        project_d = Factory(:project, :name => "D")
        project_c = Factory(:project, :name => "C")
        project_b = Factory(:project, :name => "B")
        Factory(:member_who_has_joined_project, :user => @user, :project => project_e)
        Factory(:member_who_has_joined_project, :user => @user, :project => project_d)
        Factory(:member_who_has_joined_project, :user => @user, :project => project_c).deactivate
        Factory(:member, :user => @user, :project => project_b)
        get 'show', :id => @project.id
        assigns(:member).should == @owner
        assigns(:projects).should == [@project, project_b, project_d, project_e]
      end

      it 'records the users view of the blog post' do
        pending "cant get the route to work in test, just redirects"
        post = Factory(:blog_post, :project => @project)
        expect { get :show, :id => @project.id, :blog_post_id => post.id }.
            should change { MemberBlogPostView.count }.by(1)
      end

      it "creates a UserActivity record" do
        Factory(:blog_post, :project => @project)
        expect { get :show, :id => @project.id }.
            should change { UserActivity.count }.by(1)
        user_activity = UserActivity.last
        user_activity.description.should =~ /#{@user.name} viewed #{project_path(@project.id)}/
        user_activity.action.should == "Page view"
        user_activity.member.should == @owner
      end
    end

    describe "GET new" do
      before do
        get 'new'
      end

      it "renders new" do
        response.should render_template("new")
      end

      it "assigns project" do
        assigns[:project].should be_kind_of(Project)
      end

      it "builds a member" do
        assigns[:project].members.first.should be_kind_of(Member)
      end
    end

    describe "POST create" do

      describe "with valid params" do
        before do
          attrs = Factory.attributes_for(:project).merge!(:members_attributes => {"0"=> {:role_name => 'Contributor'}})
          @parameters = {:project => attrs}
          request.env["HTTP_REFERER"] = current_user_path
        end

        it "creates a new project" do
          expect { post :create, @parameters }.to change { Project.count }.by(1)
        end

        it "creates an associated owner member" do
          expect { post :create, @parameters }.to change { Member.count }.by(1)
        end

        it "redirects to project page" do
          post :create, @parameters
          response.should redirect_to project_path(Project.last)
        end
      end
    end

    describe "member level restrictions" do
      ['Normal', 'Viewer'].each do |level|
        describe "when level #{level}" do
          before do
            @owner = Factory(:owner, :user => @user, :level => level)
            @project = @owner.project
            @valid_params = Factory.attributes_for(:project, :name => 'Test Project', :url => 'www.google.com',
                                                   :pitch => 'the pitch')
          end

          it "redirects edit requests" do
            get :edit, :id => @project.id
            response.should redirect_to(current_user_path)
          end

          it "redirects update requests" do
            put :update, :id => @project.to_param, :project => @valid_params
            response.should redirect_to(current_user_path)
          end

          it "does not update the project" do
            put :update, :id => @project.to_param, :project => @valid_params
            @project.reload.name.should_not == @valid_params[:name]
            @project.url.should_not == @valid_params[:url]
            @project.pitch.should_not == @valid_params[:pitch]
          end
        end
      end
    end

    describe "project access is restricted on GET show" do
      it "when user is not related to the project at all" do
        project = Factory(:project)
        get :show, :id => project.id
        response.should redirect_to current_user_path
      end

      pending "no confirmation" do
        it "when the user has not joined the project" do
          owner = Factory(:owner)
          member = Factory(:member, :project => owner.project, :user => @user, :level => 'Viewer', :join_code => '123456789')
          get :show, :id => member.project.id
          response.should redirect_to current_user_path
        end
      end
      
      it "when the user has been deactivated" do
        owner = Factory(:owner)
        member = Factory(:member, :user => @user, :level => "Admin", :project => owner.project)
        member.deactivate
        get :show, :id => member.project.id
        response.should redirect_to current_user_path
      end
    end
  end
end
