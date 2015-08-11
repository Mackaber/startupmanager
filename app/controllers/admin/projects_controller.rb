class Admin::ProjectsController < Admin::AdminController
  
  load_resource
  
  def export
    @blog_posts = @project.blog_posts.published.order(:published_at).page(1).per(100000)
    @posts_to_highlight = []
    @export = true
  end
  
  def index
    if request.xhr?
      order = case params[:iSortCol_0].to_i
      when 0
        "projects.id"
      when 1
        "projects.name"
      when 3
        "projects.created_at"
      when 4
        "projects.updated_at"
      when 5
        "topexp"
      when 6
        "toptask"
      end
      
      case params[:sSortDir_0]
      when "asc"
        order << " ASC"
      when "desc"
        order << " DESC"
      end
      
      order << ", projects.id DESC"
      
      @results = Project.select("projects.*, (SELECT COUNT(*) FROM experiments WHERE project_id = projects.id AND hypothesis_id IS NULL) AS topexp, (SELECT COUNT(*) FROM tasks WHERE project_id = projects.id AND hypothesis_id IS NULL) AS toptask").order(order)
      unless params[:sSearch].blank?
        s = "%#{params[:sSearch].downcase}%"
        @results = @results.where(["LOWER(name) like ?", s])
      end
      @results = @results.page(params[:iDisplayStart].to_i / params[:iDisplayLength].to_i + 1).per(params[:iDisplayLength])
      
      render :json => {
        :sEcho => params[:sEcho].to_i,
        :iTotalRecords => @results.total_count,
        :iTotalDisplayRecords => @results.total_count,
        :aaData => @results.collect do |result|
          [
            result.id,
            result.name,
            result.members.where(:level => "Owner").collect{|x| x.user.email}.sort.join(", "),
            result.created_at.strftime("%Y-%m-%d&nbsp;%I:%M%P").sub(/0([0-9]:)/, "\\1"),
            result.updated_at.strftime("%Y-%m-%d&nbsp;%I:%M%P").sub(/0([0-9]:)/, "\\1"),
            result.topexp,
            result.toptask
          ]
        end
      }
    else
      @columns = [
        "ID",
        "Name",
        "Owner(s)",
        "Created",
        "Updated",
        "Primary Experiments",
        "Primary Tasks"        
      ]
    end
  end
  
end
