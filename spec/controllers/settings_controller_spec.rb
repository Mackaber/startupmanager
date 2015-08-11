require 'spec_helper'

describe SettingsController do

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    owner = Factory(:owner)
    @user = owner.user
    sign_in @user
  end

  [:post_email, :feedback_email, :digest_email].each do |pref|
    before do
      @default_setting = @user.setting[pref]
      put :update, :id => @user.id, :setting => {:post_email => !@default_setting}
    end

    it "updates  preferences for #{pref}" do
      @user.setting.reload.post_email.should == !@default_setting
    end

    it "sets success flash message" do
      flash[:notice].should =~ /successfully changed/
    end

    it "re renders the form" do
      response.should render_template 'users/edit'
    end
  end

end
