class Api::V1::ProjectsController < Api::V1::V1BaseController
  
  load_and_authorize_resource :organization
  load_and_authorize_resource #:through => :organization, :shallow => true
  
  def create
    @project = Project.new(
      :name => params[:name],
      :organization_id => params[:organization_id]
    )
    
    if (params.has_key?(:organization))
      @project.organization_attributes = {
        :trial_end_date => Date.today+30,
        :name => params[:organization][:name],
        :organization_type => params[:organization][:organization_type]
      }
    end
    
    success = false
    Project.transaction do
      if (success = @project.save)
        @project.members.create!(
          :user_id => current_user.id,
          :is_owner => true, 
          :level => "Owner", 
          :role_name => "Contributor"
        )
        UserActivity.create!(
          :user => current_user,
          :member => current_user.membership_on(@project),
          :name => current_user.name,
          :email => current_user.email,
          :action => "Create project",
          :description => "#{current_user.name} created #{@project}"
        )  
      end  
    end
    
    if (success) 
      respond_to do |format|
        format.json do
          h = @project.to_hash
          h[:organizations] = [@project.organization.to_hash]
          h[:projects] = @project.organization.projects.collect{|x| x.to_hash}
          render(:json => h)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @project.errors)
        end
      end
    end      
  end

  def destroy
    Resque.enqueue(Jobs::DeleteProject, @project.id, current_user.id)
    render(:json => @project.to_hash);
  end
  
  def index
    projects = current_user.live_projects
    respond_to do |format|
      format.json do
        render(:json => projects.collect{|x| x.to_hash})        
      end
    end
  end
  
  def show
    t = Time.at(params[:t].to_i)
    
    projects = []
    hypotheses = []
    experiments = []
    questions = []
    tasks = []
    blog_posts = []
    canvas_items = []
    attachments = []
    comments = []
    members = []
    users = []
    
    deleted_hypothesis_ids = []
    deleted_experiment_ids = []
    deleted_question_ids = []
    deleted_task_ids = []
    deleted_blog_post_ids = []
    deleted_canvas_item_ids = []
    deleted_attachment_ids = []
    deleted_comment_ids = []
    deleted_member_ids = []
    deleted_user_ids = []
    
    if @project.updated_at.to_i > t.to_i
      logger.debug("PROJECT #{@project.updated_at} T #{t}")
      projects << @project
      
      hypotheses.concat(@project.hypotheses.where(["hypotheses.updated_at > ?", t]))
      experiments.concat(@project.experiments.where(["experiments.updated_at > ?", t]))
      questions.concat(@project.questions.where(["questions.updated_at > ?", t]))
      tasks.concat(@project.tasks.where(["tasks.updated_at > ?", t]))
      blog_posts.concat(@project.blog_posts.where(["blog_posts.updated_at > ?", t]))
      canvas_items.concat(@project.canvas_items.where(["canvas_items.updated_at > ?", t]))
      attachments.concat(@project.attachments.where(["attachments.updated_at > ?", t]))
      comments.concat(@project.comments.where(["comments.updated_at > ?", t]))
      members.concat(@project.members.where(["members.updated_at > ?", t]))
      users.concat(@project.users.where(["users.updated_at > ?", t]))
      
      @project.associated_audits.where(:action => "destroy").where(["created_at > ?", t]).each do |audit|
        case audit.auditable_type
        when "Hypothesis"
          deleted_hypothesis_ids << audit.auditable_id
        when "Experiment"
          deleted_experiment_ids << audit.auditable_id
        when "Question"
          deleted_question_ids << audit.auditable_id
        when "ProjectTask"
          deleted_task_ids << audit.auditable_id
        when "BlogPost"
          deleted_blog_post_ids << audit.auditable_id
        when "CanvasItem"
          deleted_canvas_item_ids << audit.auditable_id
        when "Attachment"
          deleted_attachment_ids << audit.auditable_id
        when "Comment"
          deleted_comment_ids << audit.auditable_id
        when "Member"
          deleted_member_ids << audit.auditable_id
        when "User"
          deleted_user_ids << audit.auditable_id
        end
      end
    end
    
    results = Hash.new{|h,k| h[k] = []}
    results[:deleted] = Hash.new{|h,k| h[k] = []}
    
    results[:projects].concat(projects.collect{|x| x.to_hash}) unless projects.empty?
    results[:hypotheses].concat(hypotheses.collect{|x| x.to_hash}) unless hypotheses.empty?
    results[:experiments].concat(experiments.collect{|x| x.to_hash}) unless experiments.empty?
    results[:questions].concat(questions.collect{|x| x.to_hash}) unless questions.empty?
    results[:tasks].concat(tasks.collect{|x| x.to_hash}) unless tasks.empty?
    results[:blog_posts].concat(blog_posts.collect{|x| x.to_hash}) unless blog_posts.empty?
    results[:canvas_items].concat(canvas_items.collect{|x| x.to_hash}) unless canvas_items.empty?
    results[:attachments].concat(attachments.collect{|x| x.to_hash}) unless attachments.empty?
    results[:comments].concat(comments.collect{|x| x.to_hash}) unless comments.empty?
    results[:members].concat(members.collect{|x| x.to_hash}) unless members.empty?
    results[:users].concat(users.collect{|x| x.to_hash}) unless users.empty?
    
    results[:deleted][:hypothesis_ids] = deleted_hypothesis_ids unless deleted_hypothesis_ids.empty?
    results[:deleted][:experiment_ids] = deleted_experiment_ids unless deleted_experiment_ids.empty?
    results[:deleted][:question_ids] = deleted_question_ids unless deleted_question_ids.empty?
    results[:deleted][:task_ids] = deleted_task_ids unless deleted_task_ids.empty?
    results[:deleted][:blog_post_ids] = deleted_blog_post_ids unless deleted_blog_post_ids.empty?
    results[:deleted][:canvas_item_ids] = deleted_canvas_item_ids unless deleted_canvas_item_ids.empty?
    results[:deleted][:attachment_ids] = deleted_attachment_ids unless deleted_attachment_ids.empty?
    results[:deleted][:comment_ids] = deleted_comment_ids unless deleted_comment_ids.empty?
    results[:deleted][:member_ids] = deleted_member_ids unless deleted_member_ids.empty?
    results[:deleted][:user_ids] = deleted_user_ids unless deleted_user_ids.empty?
    
    render(:json => results)
    
    # hypotheses = @project.hypotheses
    # gon.attachments += hypotheses.collect{|x| x.attachments}.flatten.collect{|x| x.to_hash}
    # comments = hypotheses.collect{|x| x.comments}.flatten
    # gon.comments += comments.collect{|x| x.to_hash}
    # gon.experiments += hypotheses.collect{|x| x.experiments}.flatten.collect{|x| x.to_hash}
    # gon.hypotheses += hypotheses.collect{|x| x.to_hash}
    # members = (@project.members + comments.collect{|x| x.member}.flatten).uniq
    # gon.members += members.collect{|x| x.to_hash}
    # gon.questions += hypotheses.collect{|x| x.questions}.flatten.collect{|x| x.to_hash}
    # gon.tasks += @project.tasks.collect{|x| x.to_hash}
    # gon.users += members.collect{|x| x.user.to_hash}                         
  end
  
  def update
    success = false
    Project.transaction do
      @project.lock!
      @project.attributes = load_params
      
      if (params.has_key?(:organization))
        @project.organization_attributes = {
          :trial_end_date => Date.today+30,
          :name => params[:organization][:name],
          :organization_type => params[:organization][:organization_type]
        }
      end
      
      unless params[:stripe_card_token].blank?
        if (@project.stripe_customer_id)
          if (customer = Stripe::Customer.retrieve(@project.stripe_customer_id))
            customer.card = params[:stripe_card_token]
            customer.save
          end
        else
          customer = Stripe::Customer.create(
            :card => params[:stripe_card_token],
            :email => current_user.email,
            :description => "Project #{@project.to_param}"
          )
        end
        if (customer)
          logger.debug("STRIPE #{customer.inspect}")
          @project.cc_user = current_user
          @project.stripe_customer_id = customer.id
          @project.cc_type = customer.active_card.type
          @project.cc_last4 = customer.active_card.last4
          @project.cc_exp_year = customer.active_card.exp_year
          @project.cc_exp_month = customer.active_card.exp_month   
          
          @project.payment_code = nil       
        end
      end      
      
      success = @project.save
      
      if (params.has_key?(:organization))
        @project.members.each do |member|
          unless (member.project.organization.organization_members.where(:user_id => member.user_id).count > 0)
            organization_member = member.project.organization.organization_members.build(:user_id => member.user_id, :level => ((member.user == current_user) ? "Admin" : "Normal"))
            error = !organization_member.save
          end
        end
      end
    end
    
    if success
      respond_to do |format|
        format.json do
          logger.debug("hello")
          h = {}
          h[:organizations] = [@project.organization.to_hash]
          h[:projects] = @project.organization.projects.collect{|x| x.to_hash}
          render(:json => h)          
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @project.errors)
        end
      end
    end    
  end
  
  def load_params
    attrs = {}
    [:canvas_startup_headers, :canvas_include_plan_default, :canvas_highlight_new, :name, :organization_id, :pitch, :url].each do |a|
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