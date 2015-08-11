# This controller is invoked for URLs which don't match any other routes
# (and don't match a static file, which is served directly by Nginx):

class DefaultController < ApplicationController
  
  skip_before_filter :require_login_and_password_change
  skip_authorization_check
  
  def index
    if (params[:path] == "appsumo")
      session[:promo] = "appsumo"
      redirect_to(new_user_registration_path)
      return
    end
    
    # last = params[:path].split("/").last    
    begin
      raise ActionController::RoutingError, "no path matches #{request.url}"
    rescue Exception => exception
      if (["development", "test"].include?(Rails.env))
        raise exception
      else
        @exception = exception
        @request = request
        @session = session
        @cookies = cookies
        template = File.read("app/views/layouts/system_error.erb")
        result = ERB.new(template, nil, "<>").result(binding)
        logger.error("ERROR: #{result}")
        # AdminMailer.system_error(exception, result, request).deliver
        render(:template => "/errors/404.html.erb", :status => 404)
      end
    end
  end
  
end