require 'spec_helper'

describe CustomDevise::ConfirmationsController do
  pending "no confirmation" do
    describe "user clicks the devise confirmation link (from their email) a second time" do
      before do
        request.env["devise.mapping"] = Devise.mappings[:user]
        @confirmed_user = Factory(:confirmed_user)
      end

      def click_the_link_a_second_time
        get :show, :confirmation_token => "this string is not a valid confirmation token"
      end

      context "user is not logged in" do
        it "redirects to the sign in page" do
          click_the_link_a_second_time
          response.should redirect_to new_user_session_path
        end
      end
      context "user already is logged in" do
        it "redirects to the user's projects page" do
          sign_in @confirmed_user
          click_the_link_a_second_time
          response.should redirect_to current_user_path
        end
      end
    end
  end
end