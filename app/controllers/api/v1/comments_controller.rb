class Api::V1::CommentsController < Api::V1::V1BaseController
  
  before_filter :set_project
  authorize_resource :project
  load_and_authorize_resource :through => :subject, :shallow => true
    
  def create
    success = false
    Comment.transaction do
      @project.lock!
      @comment = Comment.new({
        :blog_post => @blog_post,
        :hypothesis => @hypothesis,
        :body => params[:body],
        :member => current_user.membership_on(@project)
      })
      if (success = @comment.save)
        UserActivity.create(:user => current_user, :member => @comment.member,
                            :name => current_user.name, :email => current_user.email,
                            :action => "Create feedback", :description => "#{current_user.name} created feedback in #{@project.name}")
      end
    end
    if success
      respond_to do |format|
        format.json do
          render(:json => @comment.to_hash)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @comment.errors)
        end
      end
    end
  end
  
  def destroy
    Comment.transaction do
      @comment.subject.project.lock!
      @comment.destroy
    end
    respond_to do |format|
      format.json do
        render(:json => @comment.to_hash)
      end
    end
  end
  
  def update
    success = false
    Comment.transaction do
      @comment.subject.project.lock!
      @comment.attributes = {
        :body => params[:body]
      }
      success = @comment.save
    end
    if success
      respond_to do |format|
        format.json do
          render(:json => @comment.to_hash)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @comment.errors)
        end
      end
    end    
  end
  
  def set_project
    if params.has_key?(:id)
      @comment = Comment.find(params[:id])
      @project = @comment.project
    elsif (params.has_key?(:blog_post_id))
      @subject = @blog_post = BlogPost.find(params[:blog_post_id])
      @project = @blog_post.project
    elsif (params.has_key?(:hypothesis_id))
      @subject = @hypothesis = Hypothesis.find(params[:hypothesis_id])
      @project = @hypothesis.project    
    end
  end
  protected :set_project
  
end
