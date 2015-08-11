require "csv"

class Admin::UsersController < Admin::AdminController
  
  before_filter :find_user, :except => [:auto_complete, :export, :index]
  
  def auto_complete
    results = User.search("#{params[:q]}*", {:per_page => params[:limit]})
    render(:json => results.collect{|x| {:label => "#{x.default_email_address}", :value => x.id}})  
  end
  
  def destroy
    User.transaction do
      @user.members.destroy_all
      @user.organization_members.collect{|x| x.organization}.select{|x| x.organization_members.where(["level = 'Admin' AND user_id <> ?", @user.id]).count.zero?}.each {|x| x.destroy}    
      @user.reload.destroy
    end
    flash[:notice] = "#{@user} deleted"
    redirect_to(admin_users_path)
  end
  
  def edit
  end
  
  def export
    respond_to do |format|
      format.csv do
        out = CSV.generate do |csv|
          csv << [
            "User ID",
            "Name", 
            "Mobile Phone", 
            "Email",
            "School",
            "Gender",
            "Age",
            "Facebook",
            "Registered at", 
            "Last checkin",
            "Checkin count",
            "Last event",
            "Event count",
            "Last flag",
            "Flag count",
            "Points Earned",
            "Daily Points Expired",
            "Invitation count"
          ]
          User.registered.find_each do |result|
            last_checkin = result.checkins.order("created_at DESC").first  
            last_event = result.events.order("created_at DESC").first
            last_flag = result.flags.order("created_at DESC").first
            row = []
            row << result.id
            row << (result.name || "")
            row << (result.mobile_phone || "")
            row << (result.default_email_address ? result.default_email_address.address : "")
            row << "#{result.cached_organizations.first}"
            row << (result.gender ? result.gender.value : "")
            row << (result.birthdate ? result.age : "")
            row << (result.facebook_id ? "Y" : "")
            row << result.created_at
            row << (last_checkin ? last_checkin.created_at : "")
            row << result.checkins.count
            row << (last_event ? last_event.created_at : "")
            row << result.events.count
            row << (last_flag ? last_flag.created_at : "")
            row << result.flags.count
            row << result.points_earned__c
            row << result.points_expired
            row << result.invitations.count            
            csv << row
          end
        end
        send_data out, :type => "text/csv", :filename => "users-#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.csv"
      end
    end
  end
  
  def index
    if request.xhr?
      order = case params[:iSortCol_0].to_i
      when 0
        "users.id"
      when 1
        "users.email"
      when 2
        "users.name"
      when 3
        "users.created_at"
      when 4
        "COALESCE(users.current_sign_in_at, now() - interval '100 years')"
      end
      
      case params[:sSortDir_0]
      when "asc"
        order << " ASC"
      when "desc"
        order << " DESC"
      end
      
      order << ", users.id DESC"
      
      @results = User.order(order)
      unless params[:sSearch].blank?
        s = "#{params[:sSearch].downcase}%"
        @results = @results.where(["LOWER(email) like ? OR LOWER(name) like ?", s, s])
      end
      @results = @results.page(params[:iDisplayStart].to_i / params[:iDisplayLength].to_i + 1).per(params[:iDisplayLength])
      
      render :json => {
        :sEcho => params[:sEcho].to_i,
        :iTotalRecords => @results.total_count,
        :iTotalDisplayRecords => @results.total_count,
        :aaData => @results.collect do |result|
          [
            view_context.link_to(result.id, edit_admin_user_path(result)),
            view_context.link_to(result.email, edit_admin_user_path(result)),
            view_context.link_to(result.name, edit_admin_user_path(result)),
            result.created_at.strftime("%Y-%m-%d&nbsp;%I:%M%P").sub(/0([0-9]:)/, "\\1"),
            result.current_sign_in_at ? result.current_sign_in_at.strftime("%Y-%m-%d&nbsp;%I:%M%P").sub(/0([0-9]:)/, "\\1") : ""
          ]
        end
      }
    else
      @columns = [
        "ID",
        "Email", 
        "Name", 
        "Registered at", 
        "Logged in at"
      ]
    end
  end
  
  def masquerade
    logger.warn("User #{current_user} masquerading as user #{@user}")
    UserSession.find.destroy
    UserSession.create(@user)
    flash[:notice] = "You are now logged in as #{@user}"
    redirect_to root_path
  end
  
  def find_user
    @user = User.find(params[:id])
    true
  end
  protected :find_user
  
end
