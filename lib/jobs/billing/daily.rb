#encoding: utf-8
class Jobs::Billing::Daily < Jobs::Job
  def self.run
    today = Date.today
    
    # auto-subscribe personal plan
    Organization.lockable(today).find_each do |organization|
      if (sl = SubscriptionLevel.recommended(organization)) && sl.monthly_price.zero?
        organization.subscriptions.create!(
          :subscription_level => sl,
          :start_date => today,
          :price => sl.monthly_price
        )
      end
    end
    
    # lock all off-trial orgs w/o cc on file
    Organization.where(:auto_locked => false).find_each do |organization|
      if (organization.should_auto_lock?)
        organization.auto_locked = true
        organization.save!
      end
    end
    
    # expire promos
    Organization.where(["promotion_id IS NOT NULL AND promotion_expires_at < ?", Time.now]).find_each do |organization|
      organization.promotion = nil
      organization.promotion_expires_at = nil
      organization.save!
    end
    
    promotion = Promotion.find_by_name("15% off monthly")
    i = 0
    Organization.discountable(today).find_each do |organization|
      subscription_level = SubscriptionLevel.recommended(organization)
      unless subscription_level.nil? || (subscription_level.monthly_price || 0).zero?
        organization.promotion = promotion
        organization.promotion_expires_at = Time.now+1.day
        organization.save!

        organization.organization_members.where(:level => "Admin").each do |organization_member|
          OrganizationMailer.trial_promo(organization_member).deliver
          if ((i += 1) % 5).zero?
            sleep 1
          end
        end
      end
    end
    
    i = 0
    Organization.warnable(today).find_each do |organization|
      subscription_level = SubscriptionLevel.recommended(organization)
      unless subscription_level.nil? || (subscription_level.monthly_price || 0).zero?
        organization.organization_members.where(:level => "Admin").each do |organization_member|
          OrganizationMailer.trial_warn(organization_member).deliver
          if ((i += 1) % 5).zero?
            sleep 1
          end
        end
      end
    end
    
    Organization.billable(today).find_each do |organization|
      charge = organization.charge(today)      
      charge.save! if charge
    end
    
    Resque.enqueue(Jobs::Billing::ProcessStripe) if Rails.env == "production"
      
  end
end
