module ApplicationHelper
  
  def body_class(klass)
    content_for(:body_class, strip_tags(klass))
  end
  
  def copyright
    "Adaptada de LeanLaunchLab bajo licencia MIT Copyright &copy; #{[2011, Date.today.year].uniq.join("-")} TechCofounder, Inc."
  end
  
  def header_active
    case
    when params[:controller] == "resources"
      "resources"
    when ["projects"].include?(params[:controller]) && ["index"].include?(params[:action])
      "header-dashboard"
    when ["organizations", "organization_members"].include?(params[:controller])
      "header-organizations"
    when (["projects"].include?(params[:controller]) && !["index"].include?(params[:action])) || ["members"].include?(params[:controller])
      "header-projects"
    when ["settings"].include?(params[:controller])
      "header-settings"
    when ["help"].include?(params[:controller])
      "header-help"
    when params[:controller] == "custom_devise/sessions" && ["create", "new"].include?(params[:action])
      "signin"
    when params[:controller] == "custom_devise/registrations" && ["create", "new"].include?(params[:action])
      "signup"
    else
      ""
    end      
  end
  
  def title(page_title)
    content_for(:title, strip_tags(page_title.to_s))
  end
  
  def tracking_code
    if user_signed_in?
      return current_user.tracking_code
    else
      session[:tracking_code] ||= User.random_tracking_code
      return session[:tracking_code]
    end
  end
  
end
