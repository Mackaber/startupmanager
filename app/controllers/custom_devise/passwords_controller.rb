class CustomDevise::PasswordsController < Devise::PasswordsController
  
  skip_authorization_check
  
  def check_email
  end

  # Much of the code below is copied from the confirmations_controller.rb that is within Devise.
  # If Devise changes the implementation of the :show action in that file, the code below may need to change.
  def new
    if ((mid = (session[:mid] || params[:mid])) && (member = Member.find_by_join_code(mid)) && !member.user.has_changed_password)
      stored_location = session[:original_request]
      sign_in("user", member.user)
      session[:new_user] = true
      session[:original_request] = stored_location
      redirect_to(edit_current_user_path)
    else
      build_resource({})
      render(:template => "/devise/passwords/new")
    end
  end
  
  def edit
    self.resource = resource_class.new
    resource.reset_password_token = params[:reset_password_token]
    render(:template => "/devise/passwords/edit")
  end
  
  def after_sending_reset_password_instructions_path_for(resource_name)
    check_email_password_path
  end
  
end