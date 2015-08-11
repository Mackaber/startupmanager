class PaymentsController < ApplicationController
  
  authorize_resource :project
  before_filter :load_project
  
  def edit
  end
  
  def update
  end
  
  def load_project
    @project = Project.where(:payment_code => params[:id]).first
    render :status => 404, :text => "Project not found -- please check the URL" unless @project
  end
  protected :load_project
  
end
  
  