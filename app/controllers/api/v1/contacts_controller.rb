class Api::V1::ContactsController < Api::V1::V1BaseController
  
  skip_before_filter :require_login_and_password_change
  skip_authorization_check
  
  def create
    # ResourceMailer.question(
    #   params[:type],
    #   params[:name],
    #   params[:email],
    #   params[:company],
    #   params[:url],
    #   params[:location],
    #   params[:industry],
    #   params[:funded],
    #   params[:question]
    # ).deliver
    render(:json => {})
  end
  
end