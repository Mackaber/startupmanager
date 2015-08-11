class CustomDevise::RegistrationsController < Devise::RegistrationsController

  skip_authorization_check
  
  layout "landing"
  
  def create
    build_resource

    resource.tracking_code = (session[:tracking_code] || User.random_tracking_code)
    if session[:promo]
      resource.organizations.first.trial_end_date = Date.today+3.months
      resource.source = session[:promo]
    else
      resource.organizations.first.trial_end_date = nil # default to 30 days
    end
    
    if resource.save
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      logger.info(resource.errors.inspect)
      clean_up_passwords resource
      render :action => "new"
    end
  end  
  
  def new
    resource = build_resource({})
  end
  
  def after_sign_up_path_for(resource)
    session[:new_user] = true
    resource.save!
    root_path
  end
  
end