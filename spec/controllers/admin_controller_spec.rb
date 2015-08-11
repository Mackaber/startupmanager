require 'spec_helper'

describe AdminController do

  before do
    owner = Factory(:owner)
    @project = owner.project
    2.times {Factory(:blog_post, :member => owner)}
    @user = owner.user
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "with admin user" do

    before do
      @user.update_attribute(:email, 'ben@leanlaunchlab.com') # admin user
      sign_in @user
    end

    describe "GET export" do
      before do
        get 'export', :id => @project.to_param
      end

      it "assigns project" do
        assigns(:project).should == @project
      end

      it "assigns blog_posts" do
        assigns(:blog_posts).length.should == 2
      end

      it "renders export template" do
        response.should render_template('export')
      end
    end
  end

  describe "without admin user" do
    it "denies access" do
      sign_in @user
      get 'export', :id => @project.to_param
      response.should redirect_to('/')
    end
  end
end
