class Api::V1::QuestionsController < Api::V1::V1BaseController
  
  load_resource :project
  load_resource :hypothesis, :through => :project, :shallow => true
  load_and_authorize_resource :through => [:hypothesis, :project], :shallow => true
    
  def create
    attrs = load_params
    question = Question.new(attrs)
    success = false
    Question.transaction do
      @project.lock!
      if (success = question.save)
        UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                            :name => current_user.name, :email => current_user.email,
                            :action => "Create metric", :description => "#{current_user.name} created metric #{question} in #{@project}")
      end
    end
    
    if success
      respond_to do |format|
        format.json do
          render(:json => {:questions => [question.to_hash]})
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => question.errors)
        end
      end
    end
  end
  
  def destroy
    Question.transaction do
      @question.project.lock!
      @question.destroy
    end
    respond_to do |format|
      format.json do
        render(:json => @question.to_hash)
      end
    end
  end
  
  def update
    success = false
    Question.transaction do
      @question.project.lock!
      @question.remove_from_list if params[:position].to_i != @question.position
      @question.attributes = load_params
      if (success = @question.save)
        @question.insert_at(params[:position]) if params[:position].to_i != @question.position
        @question.save! if @question.changed?
      end
    end
    if (success)
      respond_to do |format|
        format.json do
          render(:json => @question.to_hash)
        end
      end      
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @question.errors)
        end
      end
    end    
  end
    
  def load_params
    attrs = {}
    [:title, :hypothesis_id, :project_id, :position].each do |a|
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
