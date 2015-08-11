class ResourcesController < ApplicationController
  
  skip_before_filter :require_login_and_password_change
  skip_authorization_check
  
  layout "landing"
  
  def show
    case params[:id]
    when "banking"
      render(:action => "svb")
    when "finance"
      render(:action => "rose_ryan")
    when "legal"
      render(:action => "morgan_lewis")
    end
  end
  
end