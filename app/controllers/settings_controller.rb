class SettingsController < ApplicationController
  
  before_filter :set_user
  authorize_resource :through => :user, :singleton => true
  
  def notifications
  end
  
  def profile
  end
  
  def set_user
    @user = current_user
  end
  protected :set_user
 
end