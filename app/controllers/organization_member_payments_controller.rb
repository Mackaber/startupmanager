class OrganizationMemberPaymentsController < ApplicationController
  
  before_filter :load_organization_member
  authorize_resource :organization_member
  
  def edit
  end
  
  def update
  end
  
  def load_organization_member
    logger.debug("ABC")
    @organization_member = OrganizationMember.where(:payment_code => params[:id]).first
    render :status => 404, :text => "Organization member not found -- please check the URL" unless @organization_member
  end
  protected :load_organization_member
  
end
  
