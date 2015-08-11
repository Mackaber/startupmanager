class SignupsController < ApplicationController
  
  layout "landing"
  
  skip_before_filter :require_login_and_password_change
  skip_authorization_check
  
  def create
    @signup = Signup.new(params[:signup])
    unless @signup.save
      render :text => 'Error!'
    end
  end

end
