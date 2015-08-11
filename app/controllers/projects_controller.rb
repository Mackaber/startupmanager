class ProjectsController < ApplicationController
  
  load_and_authorize_resource  
  before_filter :access_member, :except => [:index, :last, :last_canvas, :start]
  
  def canvas
    respond_to do |format|
      format.html do        
        UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                            :name => current_user.name, :email => current_user.email,
                            :action => "Page view", :description => "#{current_user.name} viewed #{canvas_project_path(@project)}") 
        gon.boxes = Box.all.collect{|x| x.to_hash}
        gon.canvas_items += @project.canvas_items.collect{|x| x.to_hash}
      end
      format.pdf do
        date = params.has_key?(:d) ? Date.parse(params[:d]) : Date.today.beginning_of_week
        send_data @project.canvas_pdf(date), :filename => "#{@project.name} Canvas #{date.strftime("%Y-%m-%d")}.pdf", :type => "application/pdf", :disposition => "inline"
      end
      format.jpeg do
        date = params.has_key?(:d) ? Date.parse(params[:d]) : Date.today.beginning_of_week
        file = Tempfile.new("canvas#{@project.id}", Dir.tmpdir, :encoding => "ascii-8bit")
        file.write(@project.canvas_pdf(date))
        file.close
        jpg_data = `convert #{file.path} jpg:-`
        file.unlink
        send_data jpg_data, :filename => "#{@project.name} Canvas #{date.strftime("%Y-%m-%d")}.jpg", :type => "image/jpeg", :disposition => "inline"
      end
    end
  end
  
  def edit
  end
  
  def index
    UserActivity.create!(:user => current_user,
                        :name => current_user.name, :email => current_user.email,
                        :action => "Page view", :description => "#{current_user.name} viewed Dashboard")
  end
  
  def interviews
    blog_posts = @project.blog_posts.published.interviews
    gon.attachments += blog_posts.collect{|x| x.attachments}.flatten.collect{|x| x.to_hash}
    gon.blog_posts += blog_posts.collect{|x| x.to_hash}
    comments = blog_posts.collect{|x| x.comments}.flatten
    gon.comments += comments.collect{|x| x.to_hash}
    members = (@project.members + comments.collect{|x| x.member}.flatten).uniq
    gon.members += members.collect{|x| x.to_hash}
    gon.users += members.collect{|x| x.user.to_hash}
  end
  
  def journal
    blog_posts = @project.blog_posts.published.updates
    gon.attachments += blog_posts.collect{|x| x.attachments}.flatten.collect{|x| x.to_hash}
    gon.blog_posts += blog_posts.collect{|x| x.to_hash}
    comments = blog_posts.collect{|x| x.comments}.flatten
    gon.comments += comments.collect{|x| x.to_hash}
    members = (@project.members + comments.collect{|x| x.member}.flatten).uniq
    gon.members += members.collect{|x| x.to_hash}
    gon.users += members.collect{|x| x.user.to_hash}
  end
  
  def last
    flash.keep
    last_accessed_member = current_user.members.active.where("accessed_at IS NOT NULL").order("accessed_at DESC").first || current_user.members.active.order("updated_at DESC").first
    if (last_accessed_member)
      redirect_to(project_path(last_accessed_member.project))
    else
      redirect_to(start_projects_path)
    end
  end

  def last_canvas
     flash.keep
     last_accessed_member = current_user.members.active.where("accessed_at IS NOT NULL").order("accessed_at DESC").first || current_user.members.active.order("updated_at DESC").first
     if (last_accessed_member)
       redirect_to(canvas_project_path(last_accessed_member.project))
     else
       redirect_to(start_projects_path)
     end
   end
  
  def show
    UserActivity.create!(:user => current_user, :member => current_user.membership_on(@project),
                        :name => current_user.name, :email => current_user.email,
                        :action => "Page view", :description => "#{current_user.name} viewed #{project_path(@project)}")
    hypotheses = @project.hypotheses
    gon.attachments += hypotheses.collect{|x| x.attachments}.flatten.collect{|x| x.to_hash}
    comments = hypotheses.collect{|x| x.comments}.flatten
    gon.comments += comments.collect{|x| x.to_hash}
    gon.experiments += hypotheses.collect{|x| x.experiments}.flatten.collect{|x| x.to_hash}
    gon.hypotheses += hypotheses.collect{|x| x.to_hash}
    members = (@project.members + comments.collect{|x| x.member}.flatten).uniq
    gon.members += members.collect{|x| x.to_hash}
    gon.questions += hypotheses.collect{|x| x.questions}.flatten.collect{|x| x.to_hash}
    gon.tasks += @project.tasks.collect{|x| x.to_hash}
    gon.users += members.collect{|x| x.user.to_hash}                     
  end
  
  def start
    project = nil
    Project.transaction do
      if current_user.organization_members.count.zero?
        o = Organization.create!(:name => "Untitled Organization", :organization_type => "Other")
        current_user.organization_members.create!(:organization => o, :level => "Admin")
      end
      if (current_user.members.active.count.zero?)
        project = Project.create!(
          :name => "Untitled Project",
          :organization_id => current_user.organization_members.first.organization_id
        )
        project.members.create!(
          :user_id => current_user.id,
          :is_owner => true, 
          :level => "Owner", 
          :role_name => "Contributor"
        )
      else
        project = current_user.members.first.project
      end
    end
    redirect_to(canvas_project_path(project, :wizard => 1))
  end
  
  def access_member
    Member.update_all("accessed_at = now()", ["project_id = ? AND user_id = ?", @project.id, current_user.id])
    true
  end
  protected :access_member

end