class Admin::AdminController < ApplicationController
  
  before_filter :check_admin
  skip_authorization_check
  
  layout "admin"
        
  def index
  end
  
  def check_admin
    unless current_user.admin
      head(403)
      return false
    end
    true
  end
  protected :check_admin
  
end
