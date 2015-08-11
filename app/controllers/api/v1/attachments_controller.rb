class Api::V1::AttachmentsController < Api::V1::V1BaseController
  
  before_filter :set_project
  load_and_authorize_resource :through => [:blog_post, :hypothesis, :project]
  
  def create
    if params.has_key?(:blog_post_id)
      item = BlogPost.find(params[:blog_post_id])
    elsif params.has_key?(:hypothesis_id)
      item = Hypothesis.find(params[:hypothesis_id])
    end
    @project = item.project
    Resque.enqueue(
      Jobs::AttachmentUpload, 
      current_user.membership_on(@project).id, 
      item.class.name, 
      item.id,  
      Base64.encode64(params[:file].read),
      params[:file].original_filename,
      params[:file].content_type
    )
    params[:file].tempfile.close
    params[:file].tempfile.unlink    
    render(:nothing => true)
  end
  
  def destroy
    Attachment.transaction do
      @attachment.item.project.lock!
      @attachment.destroy
    end
    respond_to do |format|
      format.json do
        render(:nothing => true)
      end
    end
  end
  
  def index
    if (@blog_post)
      render(:json => @blog_post.attachments.collect{|x| x.to_hash})
    elsif (@hypothesis)
      render(:json => @hypothesis.attachments.collect{|x| x.to_hash})
    else
      render(:json => [])
    end
  end
  
  def set_project
    if params.has_key?(:id)
      unless (@attachment = Attachment.find_by_id(params[:id]))
        render(:status => 404, :nothing => true)
        return false
      end
      @project = @attachment.item.project
    elsif (params.has_key?(:blog_post_id))
      unless (@blog_post = BlogPost.find_by_id(params[:blog_post_id]))
        render(:status => 404, :nothing => true)
        return false
      end
      @project = @blog_post.project
    elsif (params.has_key?(:hypothesis_id))
      unless (@hypothesis = Hypothesis.find_by_id(params[:hypothesis_id]))
        render(:status => 404, :nothing => true)
        return false
      end
      @project = @hypothesis.project    
    else
      unless (@project = Project.find_by_id(params[:project_id]))
        render(:status => 404, :nothing => true)
        return false
      end
    end    
    return true
  end
  protected :set_project
  
end