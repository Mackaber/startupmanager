class LandingController < ApplicationController

  skip_before_filter :require_login_and_password_change
  skip_authorization_check
  
  layout "landing"
  
  before_filter :check_login
  
  # can't cache when split testing
  # caches_action :index
    
  def check_login
    if user_signed_in?
      flash.keep
      if (session[:brightidea_idea_list])
        redirect_to brightidea_path
      elsif (current_user.setting.home_page)
        redirect_to(current_user.setting.home_page)
      elsif (current_user.members.active.where(:role_name => "Manager").count > 0)
        redirect_to(projects_path)
      else
        redirect_to last_projects_path
      end
      return false
    end
  end
  protected :check_login
  
  def index
    @tiered_pricing = true
  end
  
end