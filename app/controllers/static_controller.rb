class StaticController < ApplicationController

  skip_before_filter :require_login_and_password_change
  skip_authorization_check
  
  caches_page :privacy
  caches_page :terms
  
end
