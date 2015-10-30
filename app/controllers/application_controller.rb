class ApplicationController < ActionController::Base
  
  # before_filter :require_login_and_password_change
  before_filter :set_json_data_before
  after_filter :set_json_data_after

  # check_authorization :unless => :devise_controller?
  protect_from_forgery
  
  def authenticate_user!
    unless user_signed_in?
      session[:mid] = params[:mid] if params.has_key?(:mid)
      session[:original_request] = request.url
      flash.keep
    end
    super
  end

  def require_login_and_password_change
    authenticate_user!

    if current_user && !current_user.has_changed_password?
      redirect_to edit_current_user_path
    end
  end
  
  def set_json_data_before
    if !request.xhr?
      gon.attachments = Set.new
      gon.blog_posts = Set.new
      gon.canvas_items = Set.new
      gon.charges = Set.new
      gon.comments = Set.new
      gon.experiments = Set.new
      gon.hypotheses = Set.new
      gon.members = Set.new
      gon.organization_members = Set.new
      gon.organizations = Set.new
      gon.promotions = Set.new
      gon.projects = Set.new
      gon.questions = Set.new
      gon.subscription_levels = Set.new
      gon.tasks = Set.new
      gon.users = Set.new
      
      if user_signed_in?
        gon.current_user = current_user.to_hash
        gon.users << gon.current_user
        members = current_user.members.active
        gon.members += members.collect {|x| x.to_hash}
        gon.projects += members.collect{|x| x.project.to_hash}
        organization_members = current_user.organization_members
        gon.organization_members += organization_members.collect{|x| x.to_hash}
        gon.organizations += organization_members.collect{|x| x.organization.to_hash}
        gon.promotions += organization_members.select{|x| x.organization.promotion}.collect{|x| x.organization.promotion.to_hash}
        gon.subscription_levels += organization_members.collect{|x| x.organization.subscriptions.active.first}.select{|x| x}.collect{|x| x.subscription_level.to_hash}
      end
    end
    true
  end
  protected :set_json_data_before
  
  def set_json_data_after
  end
  protected :set_json_data_after

  #def ckeditor_filebrowser_scope(options = {})
  #TODO: anything need to be done here?
  #  super ({:assetable_id => current_user.id, :assetable_type => 'User'}.merge(options))
  #end

  def ckeditor_authenticate
    !authenticate_user!
    #TODO: are we ok here?
    #authorize! action_name, @asset
  end
  protected :ckeditor_authenticate

  # Set current_user as assetable
  def ckeditor_before_create_asset(asset)
    return true
  end
  protected :ckeditor_before_create_asset
  
  before_filter :set_time_zone
  def set_time_zone
    Time.zone = current_user.setting.time_zone if (user_signed_in? && current_user.setting.time_zone)
    true
  end
  protected :set_time_zone
  
  unless ["development", "test"].include?(Rails.env)
    rescue_from Exception do |exception|
      @exception = exception
      @request = request
      @session = session
      @cookies = cookies
      template = File.read("app/views/layouts/system_error.erb")
      result = ERB.new(template, nil, "<>").result(binding)
      Rails.logger.error("ERROR: #{result}")
      AdminMailer.system_error(exception, result, request).deliver
      render :template => "/errors/500.html.erb", :layout => false, :status => 500
    end
  end
  
  #override cancan default
  rescue_from CanCan::AccessDenied do |exception|
    logger.warn "WARNING: Invalid access attempt: #{exception.message}"
    redirect_to root_path
  end
  
  rescue_from ActiveRecord::RecordNotFound do |exception|
    if request.delete?
      render(:status => 200, :nothing => true)
    else
      @exception = exception
      @request = request
      @session = session
      @cookies = cookies
      template = File.read("app/views/layouts/system_error.erb")
      result = ERB.new(template, nil, "<>").result(binding)
      Rails.logger.error("ERROR: #{result}")
      AdminMailer.system_error(exception, result, request).deliver
      render :template => "/errors/500.html.erb", :layout => false, :status => 500
    end
  end  

end
