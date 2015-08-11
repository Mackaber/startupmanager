class Admin::ChargesController < Admin::AdminController
  
  load_and_authorize_resource
  
  def destroy
    @charge.destroy
    flash[:notice] = "Chage #{@charge.comments} deleted"
    redirect_to(admin_charges_path)
  end
  
  def index
    if request.xhr?
      order = case params[:iSortCol_0].to_i
      when 0
        "charges.id"
      when 1
        "charges.created_at"
      when 2
        "organizations.name"
      when 3
        "charges.amount"
      when 4
        "charges.period_start"
      end
      
      case params[:sSortDir_0]
      when "asc"
        order << " ASC"
      when "desc"
        order << " DESC"
      end
      
      order << ", charges.id DESC"
      
      @results = Charge.joins("JOIN organizations ON charges.organization_id = organizations.id")
      if (params.has_key?(:organization_id))
        @results = @results.where(:organization_id => params[:organization_id])
      end
      @results = @results.order(order)
      unless params[:sSearch].blank?
        s = "%#{params[:sSearch].downcase}%"
        @results = @results.where(["charges.id = ? OR organizations.id = ? OR LOWER(organizations.name) like ?", params[:sSearch].to_i, params[:sSearch].to_i, s])
      end
      @results = @results.page(params[:iDisplayStart].to_i / params[:iDisplayLength].to_i + 1).per(params[:iDisplayLength])
      
      render :json => {
        :sEcho => params[:sEcho].to_i,
        :iTotalRecords => @results.total_count,
        :iTotalDisplayRecords => @results.total_count,
        :aaData => @results.collect do |result|
          [
            result.id,
            result.created_at.strftime("%Y-%m-%d&nbsp;%I:%M%P").sub(/0([0-9]:)/, "\\1"),
            result.organization.name,
            view_context.number_to_currency(result.amount),
            "#{result.period_start.strftime("%Y-%m-%d")} - #{result.period_end.strftime("%Y-%m-%d")}",
            result.stripe_charge_id || "",
            result.comments || "",
            result.stripe_charge_id.nil? ? view_context.button_to("Delete", admin_charge_path(result), :method => :delete, :confirm => "Are you sure?", :class => "btn danger") : ""
          ]
        end
      }
    else
      @columns = [
        "ID",
        "Date",
        "Organization",
        "Amount",
        "Period",
        "Stripe Payment ID",
        "Comments",
        "Actions"
      ]
    end
  end
  
end
