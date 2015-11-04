require 'spec_helper'

describe ActivityStreamController do

  describe "#show" do

    describe "restricted access" do
      before do
        @ben = Factory(:confirmed_user, :email => "javier+ben@StartupManager.co")
        @dan = Factory(:confirmed_user, :email => "javier+dan@StartupManager.co")
        @kai = Factory(:confirmed_user, :email => "javier+kai@StartupManager.co")
        @lorien = Factory(:confirmed_user, :email => "javier+lorian@StartupManager.co")
        @bill = Factory(:confirmed_user, :email => "javier+bill@StartupManager.co")
        @lee = Factory(:confirmed_user, :email => "javier+lee@StartupManager.co")
      end

      context 'no signed in user' do
        it 'should not allow access' do
          get :show
          response.should be_redirect
        end
      end

      context 'user is ben, dan, kai, or lorien' do
        it "should allow access" do
          [@ben, @dan].each do |user|
            sign_out controller.current_user unless controller.current_user.nil?
            sign_in user
            get :show
            response.should_not be_redirect
          end
        end
      end

      context 'user is bill or lee' do
        it 'should not allow access' do
          sign_in @bill
          get :show
          response.should be_redirect
        end
      end
    end
  end
end
