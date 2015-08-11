class Api::V1::TasksController < Api::V1::V1BaseController
  
  load_resource :project
  load_resource :hypothesis, :through => :project, :shallow => true
  load_and_authorize_resource :class => ProjectTask, :through => [:project, :hypothesis], :shallow => true
  
  def create
    attrs = load_params
    @task = ProjectTask.new(attrs)
    success = false
    ProjectTask.transaction do
      @project.lock!
      if (success = @task.save)
        UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                            :name => current_user.name, :email => current_user.email,
                            :action => "Create task", :description => "#{current_user.name} created task #{@task} in #{@project}")
      end
    end
    
    if success
      respond_to do |format|
        format.json do
          render(:json => {:tasks => [@task.to_hash]})
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @task.errors)
        end
      end
    end
  end
  
  def destroy
    ProjectTask.transaction do
      @task.project.lock!
      @task.destroy
    end
    respond_to do |format|
      format.json do
        render(:json => @task.to_hash)
      end
    end
  end
  
  def update
    success = false
    ProjectTask.transaction do
      @task.project.lock!
      @task.remove_from_list if params[:position].to_i != @task.position
      @task.attributes = load_params
      if (success = @task.save)
        @task.insert_at(params[:position]) if params[:position].to_i != @task.position
        @task.save! if @task.changed?
      end
    end

    if success
      respond_to do |format|
        format.json do
          render(:json => {:tasks => [@task.to_hash]})
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @task.errors)
        end
      end
    end    
  end
                    
  def load_params
    attrs = {}
    [:title, :description, :due_date, :assigned_to_member_id, :hypothesis_id, :completed_at, :project_id].each do |a|
      if (a.is_a?(Array))
        key, value = a[0], a[1]
      else
        key, value = a, a
      end
      attrs[key] = params[value] if params.has_key?(value)
    end
    return attrs
  end
  protected :load_params  
    
end
  
