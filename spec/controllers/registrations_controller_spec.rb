require 'spec_helper'

describe RegistrationsController do

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "#create" do
    it "creates a UserActivity record" do
      attrs = Factory.attributes_for(:user)
      @parameters = {:user => attrs}
      
      expect { post :create, @parameters }.should change(UserActivity, :count).by(1)
      user = User.last
      user_activity = UserActivity.last
      user_activity.description.should == "#{user.name} signed up"
      user_activity.action.should == "Sign up"
      user_activity.member.should == @owner
    end
  end

end