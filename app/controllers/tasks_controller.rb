class TasksController < ApplicationController
  
  load_and_authorize_resource :project
  load_and_authorize_resource :through => :project, :class => "ProjectTask"

  before_filter :access_member
  
  def index
    UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                        :name => current_user.name, :email => current_user.email,
                        :action => "Page view", :description => "#{current_user.name} viewed #{project_tasks_path(@project)}")
    hypotheses = @project.hypotheses
    members = @project.members
    tasks = @project.tasks

    gon.hypotheses += hypotheses.collect{|x| x.to_hash}
    gon.members += members.collect{|x| x.to_hash}
    gon.tasks += tasks.collect{|x| x.to_hash}
    gon.users += members.collect{|x| x.user.to_hash}    
  end  
  
  def access_member
    @project.members.active.where(:user_id => current_user.id).first.touch(:accessed_at)
    true
  end
  protected :access_member

end