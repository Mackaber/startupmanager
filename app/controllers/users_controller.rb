class UsersController < ApplicationController

  before_filter :set_user
  # FIXME: with a singular resource this doesn't set the instance for can?
  # authorize_resource :user
  
  skip_before_filter :require_login_and_password_change, :only => [:edit, :update, :edit_settings, :update_setting]
  # before_filter :authenticate_user!, :only => [:edit, :update, :edit_settings, :update_setting]

  def edit
  end

  def edit_settings
  end

  def update
    current_password = @user.password
    if @user.update_attributes(params[:user])
      stored_location = session[:original_request]
      sign_in @user, :bypass => true
      if (stored_location)
        session[:original_request] = nil
        redirect_to stored_location
      else
        redirect_to root_path
      end
    else
      flash[:error] = @user.errors.full_messages.join(', ')
      render :edit
    end
  end

  def update_setting
    if @user.update_attributes(params[:user])
      sign_in @user, :bypass => true
      flash[:notice] = "Your settings have been updated"
    else
      flash[:error] = @user.errors.full_messages.join(', ')
    end
    render :template => 'users/edit_settings'
  end

  def need_email_confirmation
    @user = User.new :email => params['email']
  end
  
  def set_user
    unless user_signed_in?
      redirect_to(new_user_session_path)
      return false
    end
    @user = current_user
    authorize!(params[:action].to_sym, @user)
    return true
  end
  protected :set_user
end
