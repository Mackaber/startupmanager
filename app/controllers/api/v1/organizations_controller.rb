class Api::V1::OrganizationsController < Api::V1::V1BaseController
  
  load_and_authorize_resource
  
  def show
    organization_member = current_user.organization_members.where(:organization_id => params[:id]).first
    if (organization_member)
      @organization = organization_member.organization
      respond_to do |format|
        format.json do
          render(:json => @organization.to_hash)
        end
      end
    else
      render(:status => 404, :nothing => true)
    end    
  end
  
  def index
    respond_to do |format|
      format.json do
        render(:json => @organizations.collect{|x| x.to_hash})
      end
    end
  end
  
  def update    
    success = false
    Organization.transaction do
      @organization.lock!
      
      subscription = @organization.subscriptions.active.first
      
      if (params.has_key?(:subscription_level_id))
        if (params[:subscription_level_id])
          level = SubscriptionLevel.find(params[:subscription_level_id])
          yearly = params[:subscription_yearly]
          price = yearly ? level.yearly_price : level.monthly_price
      
          if (subscription && price && (subscription.subscription_level != level || subscription.yearly != yearly))
            if (@organization.on_trial?)
              subscription.destroy
            else
              subscription.update_attributes!(:end_date => Date.yesterday)
            end
            subscription = nil
          end
        
          subscription ||= @organization.subscriptions.create!(
            :subscription_level => level,          
            :yearly => yearly,
            :price => price,
            :start_date => @organization.on_trial? ? (@organization.trial_end_date+1) : Date.today
          )
        else
          subscription.destroy if subscription
        end
      end
          
      unless params[:stripe_card_token].blank?
        if (@organization.stripe_customer_id)
          if (customer = Stripe::Customer.retrieve(@organization.stripe_customer_id))
            customer.card = params[:stripe_card_token]
            customer.save
          end
        else
          customer = Stripe::Customer.create(
            :card => params[:stripe_card_token],
            :email => current_user.email,
            :description => @organization.to_param
          )
        end
        if (customer)
          logger.debug("STRIPE #{customer.inspect}")
          @organization.cc_user = current_user
          @organization.stripe_customer_id = customer.id
          @organization.cc_type = customer.active_card.type
          @organization.cc_last4 = customer.active_card.last4
          @organization.cc_exp_year = customer.active_card.exp_year
          @organization.cc_exp_month = customer.active_card.exp_month
          
          if (@organization.subscriptions.active.count.zero?)
            level = SubscriptionLevel.recommended(@organization)
            
            if (price = level.monthly_price)
              start_date = @organization.on_trial? ? (@organization.trial_end_date+1) : Date.today
            
              if (@organization.promotion && @organization.promotion.monthly_discount_percent)
                price = (price * (100-@organization.promotion.monthly_discount_percent)/100.0).round(2)
                end_date = (start_date + @organization.promotion.months.months - 1).end_of_month
              end
              
              @organization.subscriptions.create!(
                :subscription_level => level,
                :price => price,
                :start_date => start_date,
                :end_date => end_date
              )
            end
          end
        end
      end
      success = @organization.save
    end
    
    if success
      respond_to do |format|
        format.json do
          render(:json => @organization.reload.to_hash)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:status => 400, :json => @organization.errors)
        end
      end
    end
  end 
    
end