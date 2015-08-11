class Admin::UserActivitiesController < Admin::AdminController
  
  def index
    if request.xhr?
      order = case params[:iSortCol_0].to_i
      when 0
        "user_activities.created_at"
      when 1
        "user_activities.name"
      when 2
        "user_activities.email"
      when 3
        "user_activities.action"
      end
      
      case params[:sSortDir_0]
      when "asc"
        order << " ASC"
      when "desc"
        order << " DESC"
      end
      
      order << ", user_activities.id DESC"
      
      @results = UserActivity.order(order)
      unless params[:sSearch].blank?
        s = "#{params[:sSearch].downcase}%"
        ss = "%#{params[:sSearch].downcase}%"
        @results = @results.where(["LOWER(email) like ? OR LOWER(name) like ? OR LOWER(action) like ? OR LOWER(description) like ?", s, s, s, ss])
      end
      @results = @results.page(params[:iDisplayStart].to_i / params[:iDisplayLength].to_i + 1).per(params[:iDisplayLength])
      
      render :json => {
        :sEcho => params[:sEcho].to_i,
        :iTotalRecords => @results.total_count,
        :iTotalDisplayRecords => @results.total_count,
        :aaData => @results.collect do |result|
          [
            result.created_at.strftime("%Y-%m-%d&nbsp;%I:%M%P").sub(/0([0-9]:)/, "\\1"),
            result.name,
            result.email,
            result.action,
            result.description,
            result.action.normalize
          ]
        end
      }
    else
      @columns = [
        "Date",
        "Name",
        "Email",
        "Action",
        "Description"
      ]
    end
  end
    
end
