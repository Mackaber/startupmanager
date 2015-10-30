class CustomDevise::SessionsController < Devise::SessionsController
  skip_authorization_check
  
  def create
    bll = session[:brightidea_idea_list]
    super
    session[:brightidea_idea_list] = bll
  end
    
end