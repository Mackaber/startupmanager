class Api::V1::HypothesesController < Api::V1::V1BaseController
  
  load_and_authorize_resource :project
  load_and_authorize_resource :through => :project, :shallow => true
    
  def create
    attrs = load_params
    attrs[:project] = @project
    # FIXME: workaround for duplicate hypotheses being created
    success = false
    template = Hypothesis.new(attrs)
    unless (hypothesis = @project.hypotheses.where(:title => template.title).first)
      hypothesis = template
      Hypothesis.transaction do
        @project.lock!
        if (success = hypothesis.save)
          UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                              :name => current_user.name, :email => current_user.email,
                              :action => "Create hypothesis", :description => "#{current_user.name} created hypothesis #{hypothesis} in #{@project}")
        end
      end
    end
    if success
      respond_to do |format|
        format.json do
          hypotheses = [hypothesis]
          render(:json => {
            :projects => [hypothesis.project].collect{|x| x.to_hash},
            :experiments => hypotheses.collect{|x| x.experiments}.flatten.collect{|x| x.to_hash},
            :hypotheses => hypotheses.collect{|x| x.to_hash},
            :questions => hypotheses.collect{|x| x.questions}.flatten.collect{|x| x.to_hash},
            :tasks => hypotheses.collect{|x| x.tasks}.flatten.collect{|x| x.to_hash}
          })          
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => hypothesis.errors)
        end
      end
    end
  end
  
  def destroy
    Hypothesis.transaction do
      @hypothesis.project.lock!
      @hypothesis.destroy
    end
    respond_to do |format|
      format.json do
        render(:json => @hypothesis.to_hash)
      end
    end
  end
  
  def index
    if @project
      render(:json => @project.hypotheses.collect{|x| x.to_hash})
    end
  end    
  
  def update
    success = false
    Hypothesis.transaction do
      @hypothesis.project.lock!
      if !params[:position].blank? && (params[:position].to_i != @hypothesis.position)
        @hypothesis.remove_from_list 
      end
      @hypothesis.experiments.select{|e| params.has_key?(:experiments_attributes) && !params[:experiments_attributes].any?{|x| x["id"] == e.id}}.each{|e| e.destroy}
      @hypothesis.questions.select{|e| params.has_key?(:questions_attributes) && !params[:questions_attributes].any?{|x| x["id"] == e.id}}.each{|e| e.destroy}
      @hypothesis.tasks.select{|e| params.has_key?(:tasks_attributes) && !params[:tasks_attributes].any?{|x| x["id"] == e.id}}.each{|e| e.destroy}
      @hypothesis.attributes = load_params
      if (success = @hypothesis.save)
        if !params[:position].blank? && (params[:position].to_i != @hypothesis.position)
          @hypothesis.insert_at(params[:position]) 
        end
        @hypothesis.save! if @hypothesis.changed?
      end
    end
    if (success)
      respond_to do |format|
        format.json do
          hypotheses = [@hypothesis]
          render(:json => {
            :projects => [@hypothesis.project].collect{|x| x.to_hash},
            :experiments => hypotheses.collect{|x| x.experiments}.flatten.collect{|x| x.to_hash},
            :hypotheses => hypotheses.collect{|x| x.to_hash},
            :questions => hypotheses.collect{|x| x.questions}.flatten.collect{|x| x.to_hash},
            :tasks => hypotheses.collect{|x| x.tasks}.flatten.collect{|x| x.to_hash}
          })
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @hypothesis.errors)
        end
      end
    end    
  end
  
  def load_params
    attrs = {}
    [:status, :title, :description, :completed_at, :completed_reason, :hypothesis_id, :questions_attributes, :experiments_attributes, :tasks_attributes].each do |a|
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
