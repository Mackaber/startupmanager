class OrganizationsController < ApplicationController
  
  load_and_authorize_resource :except => [:last]
  skip_authorization_check :only => [:last]
  
  def last
    flash.keep
    last_accessed_member = current_user.members.active.where("accessed_at IS NOT NULL").order("accessed_at DESC").first || current_user.members.active.order("updated_at DESC").first
    if (last_accessed_member)
      redirect_to(payment_organization_path(last_accessed_member.project.organization))
    else
      redirect_to(start_projects_path)
    end
  end
  
  def payment
    gon.organization_members += @organization.organization_members.collect{|x| x.to_hash}
    gon.users += @organization.organization_members.collect.collect{|x| x.user.to_hash}
    gon.charges += @organization.charges.collect{|x| x.to_hash}
    gon.subscription_levels += SubscriptionLevel.all.collect{|x| x.to_hash}
  end
  
  def show
    gon.organization_members += @organization.organization_members.collect{|x| x.to_hash}
    gon.users += @organization.organization_members.collect{|x| x.user.to_hash}
    projects = @organization.projects
    gon.projects += projects.collect{|x| x.to_hash}
    members = projects.collect{|x| x.members.active}.flatten
    gon.members += members.collect{|x| x.to_hash}
    gon.users += members.collect{|x| x.user.to_hash}
    gon.subscription_levels += SubscriptionLevel.all.collect{|x| x.to_hash}
  end

end