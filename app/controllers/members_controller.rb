class MembersController < ApplicationController
  
  load_resource :project
  authorize_resource :project, :except => [:remove]
  load_and_authorize_resource :through => :project

  skip_before_filter :require_login_and_password_change, :only => [:remove]
  skip_authorization_check :only => [:remove]

  before_filter :access_member, :except => [:remove]
  
  def index
    UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                        :name => current_user.name, :email => current_user.email,
                        :action => "Page view", :description => "#{current_user.name} viewed #{project_members_path(@project)}")
    # current_user's member records are already added by ApplicationController#set_current_user_js
    members = @project.members.active.where(["user_id <> ?", current_user.id])
    gon.members += members.collect{|x| x.to_hash}
    gon.users += members.collect{|x| x.user.to_hash}
    organization_members = @project.organization.organization_members
    gon.organization_members += organization_members.collect{|x| x.to_hash}
    gon.users += organization_members.collect{|x| x.user.to_hash}
  end  

  def remove
    unless (@member.join_code == params[:mid])
      flash[:error] = "Sorry, could not locate that project membership.  It may have already been deactivated."
      redirect_to(root_path)
    end
  end
  
  def access_member
    @project.members.active.where(:user_id => current_user.id).first.touch(:accessed_at)
    true
  end
  protected :access_member

end