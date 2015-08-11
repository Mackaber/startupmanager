require 'spec_helper'

describe CommentsController do

  describe "#create" do
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

        describe "user activity log" do
          before do
            setup_member_and_project("Admin")
            member = Factory(:member_who_has_joined_project, :project => @project)
            @blog_post = Factory(:blog_post, :member => member)

            @params = {:comment => {:blog_post_id => @blog_post.id, :member_id => @member.id,
                                    :body => "some comment content", :prompt => 'Enter Feedback...'}}
          end
          it "creates a UserActivity record" do
            expect { post :create, @params }.should change(UserActivity, :count).by(1)
            comment = Comment.last
            user_activity = UserActivity.last
            user_activity.description.should == "#{@member.user.name} created feedback in #{@project.name}"
            user_activity.action.should == "Create feedback"
            user_activity.member.should == @member
          end
        end

        describe 'permission level restriction' do
          %w(Admin Normal Viewer).each do |level|
            context "level is #{level}" do
              before do
                setup_member_and_project(level)
                member2 = Factory(:member_who_has_joined_project, :project => @project)
                @blog_post = Factory(:blog_post, :member => member2)

                @params = {:comment => {:blog_post_id => @blog_post.id, :member_id => @member.id,
                                        :body => "some comment content", :prompt => 'Enter Feedback...'}}
              end

              if level == "Viewer"
                it 'should NOT create the comment' do
                  expect { post :create, @params }.should_not change(Comment, :count)
                end

                it 'should redirect to the user page' do
                  post :create, @params
                  response.should redirect_to current_user_path
                end

              elsif level != "Viewer"

                it 'should produce a json response' do
                  post :create, @params
                  response.headers['Content-Type'].should =~ /json/
                  response.should_not be_redirect
                end

                it 'should create the comment' do
                  expect { post :create, @params }.should change(Comment, :count).by(1)
                end

                it 'should not create a comment for a blog post that does not belong to this project' do
                  owner2 = Factory(:owner)
                  blog_post2 = Factory(:blog_post, :member => owner2)
                  params = {:comment => {:blog_post_id => blog_post2.id, :member_id => @member.id, :body => "some comment content"}}
                  expect { post :create, params }.should_not change(Comment, :count)
                  response.should redirect_to current_user_path
                end
              end
            end
          end
        end
      end

      context 'user is NOT member of project' do
        it 'should not create' do
          owner = Factory(:owner)
          blog_post = Factory(:blog_post, :member => owner)
          params = {:comment => {:blog_post_id => blog_post.id, :member_id => owner.id, :body => "some comment content"}}
          expect { post :create, params }.should_not change(Comment, :count)
          response.should redirect_to current_user_path
        end
      end
    end

    context 'un-authenticated user' do
      it 'should redirect to the login screen' do
        owner = Factory(:owner)
        blog_post = Factory(:blog_post, :member => owner)
        params = {:comment => {:blog_post_id => blog_post.id, :member_id => owner.id, :body => "some comment content"}}
        expect { post :create, params }.should_not change(Comment, :count)
        response.should redirect_to new_user_session_path
      end
    end
  end
end
