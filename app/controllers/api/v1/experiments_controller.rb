class Api::V1::ExperimentsController < Api::V1::V1BaseController
  
  load_resource :project
  load_resource :hypothesis, :through => :project, :shallow => true
  load_and_authorize_resource :through => [:hypothesis, :project], :shallow => true
    
  def create
    attrs = load_params
    experiment = Experiment.new(attrs)
    success = false
    Experiment.transaction do
      @project.lock!
      if (success = experiment.save)
        UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                            :name => current_user.name, :email => current_user.email,
                            :action => "Create experiment", :description => "#{current_user.name} created experiment #{experiment} in #{@project}")
      end
    end
    
    if success
      respond_to do |format|
        format.json do
          experiments = [experiment.to_hash]
          hypotheses = [experiment.hypothesis.to_hash]
          render(:json => {:experiments => experiments, :hypotheses => hypotheses})
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => experiment.errors)
        end
      end
    end
  end
  
  def destroy
    Experiment.transaction do
      @experiment.project.lock!
      @experiment.destroy
    end
    respond_to do |format|
      format.json do
        render(:json => @experiment.to_hash)
      end
    end
  end
  
  def update
    success = false
    Experiment.transaction do
      @experiment.project.lock!
      @experiment.remove_from_list if params[:position].to_i != @experiment.position
      @experiment.attributes = load_params
      if (success = @experiment.save)
        @experiment.insert_at(params[:position]) if params[:position].to_i != @experiment.position
        @experiment.save! if @experiment.changed?
      end
    end
    if (success)
      respond_to do |format|
        format.json do
          experiments = [@experiment.to_hash]
          hypotheses = [@experiment.hypothesis.to_hash]
          render(:json => {:experiments => experiments, :hypotheses => hypotheses})
        end
      end      
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @experiment.errors)
        end
      end
    end    
  end
    
  def load_params
    attrs = {}
    [:status, :title, :description, :start_date, :end_date, :success_criteria, :hypothesis_id, :project_id, :completed_at].each do |a|
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
