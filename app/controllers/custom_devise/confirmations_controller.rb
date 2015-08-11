class CustomDevise::ConfirmationsController < Devise::ConfirmationsController

  skip_authorization_check

  # Much of the code below is copied from the confirmations_controller.rb that is within Devise.
  # If Devise changes the implementation of the :show action in that file, the code below may need to change.
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      set_flash_message(:notice, :confirmed) if is_navigational_format?
      sign_in(resource_name, resource)
      respond_with_navigational(resource) { redirect_to redirect_location(resource_name, resource) }
    else
      if current_user.nil?
        redirect_to new_user_session_path
      else
        redirect_to root_path
      end
    end
  end

  def after_resending_confirmation_instructions_path_for(resource_name)
    need_email_confirmation_path(params['user'].select { |k| k == 'email' })
  end
end