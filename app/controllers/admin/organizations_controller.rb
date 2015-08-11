require "csv"

class Admin::OrganizationsController < Admin::AdminController
  
  load_resource
  
  def destroy
    @organization.destroy
    flash[:notice] = "#{@organization} deleted"
    redirect_to(admin_organizations_path)
  end
    
  def edit
  end
  
  def index
    if request.xhr?
      order = case params[:iSortCol_0].to_i
      when 0
        "organizations.id"
      when 1
        "organizations.name"
      when 2
        "organizations.created_at"
      when 3
        "pc"
      when 4
        "mc"
      when 5
      when 6
        "ct"
      when 7
        "ot"
      end
      
      case params[:sSortDir_0]
      when "asc"
        order << " ASC"
      when "desc"
        order << " DESC"
      end
      
      order << ", organizations.id DESC"
      
      @results = Organization.select("organizations.*, (SELECT COUNT(*) FROM projects WHERE organization_id = organizations.id) AS pc, (SELECT COUNT(*) FROM organization_members WHERE organization_id = organizations.id) AS mc, COALESCE((SELECT SUM(amount) FROM charges WHERE organization_id = organizations.id), 0) AS ct, COALESCE((SELECT SUM(amount) FROM charges WHERE organization_id = organizations.id AND stripe_charge_id IS NULL), 0) AS ot").order(order)
      unless params[:sSearch].blank?
        s = "%#{params[:sSearch].downcase}%"
        @results = @results.where(["id = ? OR LOWER(name) like ?", params[:sSearch].to_i, s])
      end
      @results = @results.page(params[:iDisplayStart].to_i / params[:iDisplayLength].to_i + 1).per(params[:iDisplayLength])
      
      render :json => {
        :sEcho => params[:sEcho].to_i,
        :iTotalRecords => @results.total_count,
        :iTotalDisplayRecords => @results.total_count,
        :aaData => @results.collect do |result|
          [
            view_context.link_to(result.id, edit_admin_organization_path(result)),
            view_context.link_to(result.name, edit_admin_organization_path(result)),
            result.created_at.strftime("%Y-%m-%d&nbsp;%I:%M%P").sub(/0([0-9]:)/, "\\1"),
            result.pc,
            result.mc,
            result.on_trial? ?
              "Trial ends #{result.trial_end_date}"
              : "#{result.subscriptions.active.first}",
            view_context.link_to(view_context.number_to_currency(result.charges.sum(:amount)), admin_charges_path(:organization_id => result.id)),
            view_context.link_to(view_context.number_to_currency(result.charges.outstanding.sum(:amount)), admin_charges_path(:organization_id => result.id))
          ]
        end
      }
    else
      @columns = [
        "ID",
        "Name", 
        "Created",
        "# Projects", 
        "# Members", 
        "Plan",
        "Total Charges",
        "Current Balance"
      ]
    end
  end
  
  def update
    params[:organization].delete(:subscriptions_attributes) if @organization.subscriptions.empty? && params[:organization][:subscriptions_attributes]["0"][:subscription_level_id].blank?
    @organization.attributes = params[:organization]
    if (@organization.save)
      flash[:notice] = "#{@organization} updated"
      redirect_to(admin_organizations_path)
    else
      render(:action => "edit")
    end
  end
    
end
