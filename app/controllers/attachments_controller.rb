class AttachmentsController < ApplicationController
  
  load_and_authorize_resource :project
  load_and_authorize_resource

  before_filter :access_member
  
  def show
    redirect_to(@attachment.data.expiring_url(7200))
  end
  
  def access_member
    @project.members.active.where(:user_id => current_user.id).first.touch(:accessed_at)
    true
  end
  protected :access_member

end