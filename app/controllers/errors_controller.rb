class ErrorsController < ApplicationController
  
  skip_before_filter :require_login_and_password_change
  skip_authorization_check
  
  def create
    @message = params[:message]
    @stacktrace = params[:stacktrace]
    @request = request
    @session = session
    @cookies = cookies
    template = File.read("app/views/layouts/system_error.erb")
    result = ERB.new(template, nil, "<>").result(binding)
    logger.error("ERROR: #{result}")
    AdminMailer.system_error(@message, result, request).deliver
    render :nothing => true
  end
  
end