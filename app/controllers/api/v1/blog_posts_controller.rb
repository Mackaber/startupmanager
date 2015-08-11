class Api::V1::BlogPostsController < Api::V1::V1BaseController  
  
  load_and_authorize_resource :project
  load_and_authorize_resource :through => :project, :shallow => true
      
  def create
    attrs = load_params
    attrs[:project] = @project
    attrs[:post_type] = params[:post_type]
    blog_post = BlogPost.new(attrs)
    
    success = false
    BlogPost.transaction do
      @project.lock!
      blog_post.publish
      if (success = blog_post.save)
        UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                            :name => current_user.name, :email => current_user.email,
                            :action => "Create blog post", :description => "#{current_user.name} created blog post #{blog_post} in #{@project}")
      end
    end
    if success
      respond_to do |format|
        format.json do
          render(:json => blog_post.to_hash)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => blog_post.errors)
        end
      end
    end
  end
  
  def destroy
    BlogPost.transaction do
      @blog_post.project.lock!
      @blog_post.destroy
    end
    respond_to do |format|
      format.json do
        render(:json => @blog_post.to_hash)
      end
    end
  end
  
  def index
    if @project
      render(:json => @project.blog_posts.published.collect{|x| x.to_hash})
    end
  end
  
  def update
    @blog_post.attributes = load_params
    success = false
    BlogPost.transaction do
      @blog_post.project.lock!
      success = @blog_post.save
    end
    if success
      respond_to do |format|
        format.json do
          render(:json => @blog_post.to_hash)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @blog_post.errors)
        end
      end
    end    
  end
    
  def load_params
    attrs = {}
    [:urgent, [:subject, :title], [:body, :description], :the_ask, :date, :text1, :text2].each do |a|
      if (a.is_a?(Array))
        key, value = a[0], a[1]
      else
        key, value = a, a
      end
      attrs[key] = params[value] if params.has_key?(value)
    end
    attrs[:member] = current_user.membership_on(@project)
    return attrs
  end
  protected :load_params
end
  