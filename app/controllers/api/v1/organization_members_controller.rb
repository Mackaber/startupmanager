require "csv"

class Api::V1::OrganizationMembersController < Api::V1::V1BaseController
  
  load_and_authorize_resource :organization
  load_and_authorize_resource :through => :organization, :shallow => true
  skip_authorization_check :only => [:destroy]
  
  def create
    success = false
    member = nil
    OrganizationMember.transaction do
      @organization.lock!
      attrs = load_params
      member = process_member(params[:user][:name], params[:user][:email], attrs[:level])
      if (success = (member && member.errors.empty?))
        UserActivity.create(:user => current_user,
                            :member => nil,
                            :name => current_user.name,
                            :email => current_user.email,
                            :action => "Invited",
                            :description => "#{current_user.name} invited #{member.user.name} to organization #{@organization.name}")
      end
    end
    if (success)
      respond_to do |format|
        format.json do
          organization_members = [member]
          render(:json => {
            :organizations => [member.organization.to_hash],
            :organization_members => organization_members.collect{|x| x.to_hash},
            :users => organization_members.collect{|x| x.user.to_hash}
          })
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => member.errors)
        end
      end
    end
  end
  
  def destroy
    authorize! :destroy, @organization_member
    OrganizationMember.transaction do
      @organization_member.organization.lock!
      @organization_member.destroy
    end
    respond_to do |format|
      format.json do
        h = @organization_member.to_hash
        h[:organizations] = [@organization_member.organization.to_hash]
        render(:json => h)
      end
    end
  end
  
  def import
    members = []
    errors = []
    OrganizationMember.transaction do
      @organization.lock!
      CSV.new(params[:data], :col_sep => "\t").each_with_index do |row,i|
        name = row[0]
        email = row[1]
        level = row[2]      
        # blank row
        if (name.blank? && email.blank? && level.blank?)
          next
        end
        # header row
        if (i == 0 && !Devise.email_regexp.match(email))
          next
        end
        if (name.blank? || !Devise.email_regexp.match(email))
          errors << row
        else
          if level.blank?
            level = "Normal" 
          else
            level = level.strip.titlecase
          end        
          member = process_member(name, email, level)
          if (member && member.errors.empty?)
            members << member
          else
            errors << row
          end
        end
      end    
    end
    render(:json => {
      :organization_members => members.collect{|x| h = x.to_hash; h[:user] = x.user.to_hash; h},
      :errors => errors
    })
  end
    
  def update
    success = false
    OrganizationMember.transaction do
      @organization_member.organization.lock!
      @organization_member.attributes = load_params
      authorize! :assign_roles, @organization_member if (@organization_member.level_changed?)      
      
      unless params[:stripe_card_token].blank?
        if (@organization_member.stripe_customer_id)
          if (customer = Stripe::Customer.retrieve(@organization_member.stripe_customer_id))
            customer.card = params[:stripe_card_token]
            customer.save
          end
        else
          customer = Stripe::Customer.create(
            :card => params[:stripe_card_token],
            :email => current_user.email,
            :description => "Organization member #{@organization_member.to_param}"
          )
        end
        if (customer)
          logger.debug("STRIPE #{customer.inspect}")
          @organization_member.stripe_customer_id = customer.id
          @organization_member.cc_type = customer.active_card.type
          @organization_member.cc_last4 = customer.active_card.last4
          @organization_member.cc_exp_year = customer.active_card.exp_year
          @organization_member.cc_exp_month = customer.active_card.exp_month
          
          @organization_member.process_payment!
          
          @organization_member.payment_code = nil       
        end
        OrganizationMailer.member_receipt(@organization_member).deliver
        flash[:notice] = "Thank you for submitting your payment.  A receipt has been emailed to #{@organization_member.user.email}."
      end      
      
      success = @organization_member.save
    end
    if success
      respond_to do |format|
        format.json do
          render(:json => @organization_member.to_hash)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @organization_member.errors)
        end
      end
    end    
  end
    
  def load_params
    attrs = {}
    [:level].each do |a|
      if (a.is_a?(Array))
        key, value = a[0], a[1]
      else
        key, value = a, a
      end
      attrs[key] = params[value] if params.has_key?(value)
    end
    return attrs
  end
  protected :load_params  
  
  def process_member(name, email, level)
    unless (user = User.find_by_email(email.downcase))
      new_user = true
      unguessable_password = (0...20).map { 65.+(rand(25)).chr }.join
      user = User.new(
        :email => email,
        :name => name,
        :password => unguessable_password,
        :password_confirmation => unguessable_password
      )
      user.has_changed_password = false
      if (user.save)      
      else
        render(:status => 400, :json => user.errors)
        return nil
      end
    end
    if (member = user.organization_members.where(:organization_id => @organization.id).first)
    else
      new_member = true
      member = OrganizationMember.new
      member.user = user
      member.organization = @organization
    end
    member.level = level    
    member.save
    return member
  end
  protected :process_member
    
end
