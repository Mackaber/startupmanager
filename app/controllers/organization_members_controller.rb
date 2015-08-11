class OrganizationMembersController < ApplicationController
  
  load_and_authorize_resource :organization
  load_and_authorize_resource :through => :organization
  
  def index
    if params.has_key?(:organization_id)
      organization_member = current_user.organization_members.where(:organization_id => params[:organization_id]).first
      @organization = organization_member.organization if organization_member
    else
      last_accessed_member = current_user.members.active.where("accessed_at IS NOT NULL").order("accessed_at DESC").first || current_user.members.active.order("updated_at DESC").first
      @organization = last_accessed_member.project.organization if last_accessed_member
    end
    gon.organization_members += @organization.organization_members.collect{|x| x.to_hash}
    gon.users += @organization.organization_members.collect{|x| x.user.to_hash}    
    unless (@organization)
      render(:status => 404, :nothing => true)
    end
  end  

end