class Api::V1::CanvasItemsController < Api::V1::V1BaseController  
  
  load_and_authorize_resource :project
  load_and_authorize_resource :through => :project, :shallow => true
      
  def create
    attrs = load_params
    attrs[:project] = @project
    canvas_item = CanvasItem.new(attrs)
    
    success = false
    CanvasItem.transaction do
      @project.lock!
      if (success = canvas_item.save)
        UserActivity.create(:user => current_user,
                            :member => current_user.membership_on(@project),
                            :name => current_user.name,
                            :email => current_user.email,
                            :action => "Create canvas item",
                            :description => "#{current_user.name} created canvas item in #{canvas_item.project.name}")
      end
    end
    if success
      respond_to do |format|
        format.json do
          render(:json => {:canvas_items => [canvas_item.to_hash]})
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => canvas_item.errors)
        end
      end
    end
  end
  
  def destroy
    CanvasItem.transaction do
      @canvas_item.project.lock!
      @canvas_item = @canvas_item.create_updated({:deleted => true})
    end
    respond_to do |format|
      format.json do
        render(:json => @canvas_item.to_hash)
      end
    end
  end
  
  def update
    attributes = load_params      
    success = nil
    CanvasItem.transaction do
      @canvas_item.project.lock!
      @new_item = @canvas_item.create_updated(attributes.merge(:updated => true))
      success = @new_item.errors.empty?
    end
    if success
      @canvas_item.reload       # attributes like inactive_at changed
      respond_to do |format|
        format.json do
          items = [@canvas_item, @new_item]
          render(:json => {
            :canvas_items => items.collect{|x| x.to_hash}
          })
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @new_item.errors)
        end
      end
    end    
  end
    
  def load_params
    attrs = {}
    [[:text, :title], :description, :category, :status, :x, :y, :z, :display_color, :include_in_plan].each do |a|
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
