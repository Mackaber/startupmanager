require 'spec_helper'

describe ActivityStreamController do

  describe "#show" do

    describe "restricted access" do
      before do
        @ben = Factory(:confirmed_user, :email => "ben@leanlaunchlab.com")
        @dan = Factory(:confirmed_user, :email => "dan@leanlaunchlab.com")
        @kai = Factory(:confirmed_user, :email => "kai@leanlaunchlab.com")
        @lorien = Factory(:confirmed_user, :email => "lorien.henrywilkins@gmail.com")
        @bill = Factory(:confirmed_user, :email => "bill@blazingcloud.net")
        @lee = Factory(:confirmed_user, :email => "lee@blazingcloud.net")
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
