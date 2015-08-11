class Organization < ActiveRecord::Base

  belongs_to :cc_user, :class_name => "User", :foreign_key => "cc_user_id"
  has_many :charges
  has_many :organization_members, :dependent => :destroy
  has_many :projects, :dependent => :destroy
  belongs_to :promotion
  has_many :subscriptions
    
  acts_as_audited
  
  accepts_nested_attributes_for :subscriptions
  
  include NamedEntity
  
  include ActionView::Helpers::NumberHelper     # number_to_currency
  
  accepts_nested_attributes_for :organization_members
  
  validates_presence_of :organization_type, :message => "please select one"
  
  before_validation do |organization|
    organization.organization_type ||= "Other"
  end
    
  before_create do |organization|
    organization.trial_end_date ||= Date.today+30
  end
  
  before_update do |organization|
    if (organization.auto_locked && !organization.should_auto_lock?)
      organization.auto_locked = false
    elsif (!organization.auto_locked && organization.should_auto_lock?)
      organization.auto_locked = true
    end
    
    # locking affects permissions
    if (organization.auto_locked_changed?)
      organization.organization_members.each {|x| x.touch}
      organization.projects.each {|p| p.members.each{|x| x.touch}}
    end
    
    if (organization.member_price_was.nil? && organization.member_price)
      organization.organization_members.where(["level <> 'Admin'"]).each {|x| x.assign_payment_code!}
    end
  end
  
  scope(
    :accessible_by,
    lambda do |ability|
      joins("JOIN organization_members ON organizations.id = organization_members.organization_id")
      .where(["organization_members.user_id = ?", ability.user.id])
    end
  )
  
  scope(
    :off_trial,
    lambda do |date|
      where(["organizations.trial_end_date IS NULL OR organizations.trial_end_date < ?", date])
    end
  )
  
  scope(
    :lockable,
    lambda do |date|
      off_trial(date).
      select("organizations.*").
      joins("LEFT JOIN subscriptions ON organizations.id = subscriptions.organization_id AND subscriptions.start_date <= '#{(date).to_s(:db)}' AND (subscriptions.end_date IS NULL OR subscriptions.end_date >= '#{(date).to_s(:db)}')").
      where("subscriptions.id IS NULL").
      where(:stripe_customer_id => nil).
      where(:invoice_billing => false)
    end
  )
  
  scope(
    :billable,
    lambda do |date|
      select("organizations.*").
      joins("JOIN subscriptions ON organizations.id = subscriptions.organization_id").
      where(["organizations.trial_end_date IS NULL OR organizations.trial_end_date < ?", date]).
      where(["subscriptions.start_date <= ?", date]).
      where(["subscriptions.end_date IS NULL OR subscriptions.end_date >= ?", date]).
      where("subscriptions.price > 0").
      where("organizations.stripe_customer_id IS NOT NULL")
    end
  )

  scope(
    :discountable,
    lambda do |date|
      select("organizations.*").
      joins("LEFT JOIN subscriptions ON organizations.id = subscriptions.organization_id AND subscriptions.start_date <= '#{(date+7).to_s(:db)}' AND (subscriptions.end_date IS NULL OR subscriptions.end_date >= '#{(date+7).to_s(:db)}')").
      where("subscriptions.id IS NULL OR subscriptions.price > 0").
      where(:trial_end_date => date + 6).
      where(:invoice_billing => false).
      where(:stripe_customer_id => nil)
    end
  )

  scope(
    :warnable,
    lambda do |date|
      select("organizations.*").
      joins("LEFT JOIN subscriptions ON organizations.id = subscriptions.organization_id AND subscriptions.start_date <= '#{(date+3).to_s(:db)}' AND (subscriptions.end_date IS NULL OR subscriptions.end_date >= '#{(date+3).to_s(:db)}')").
      where("subscriptions.id IS NULL OR subscriptions.price > 0").
      where(["trial_end_date BETWEEN ? AND ?", date, date+2]).
      where(:invoice_billing => false).
      where(:stripe_customer_id => nil)
    end
  )  
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      subscription = self.subscriptions.active.first || self.subscriptions.where(:end_date => nil).first
      recommended = SubscriptionLevel.recommended(self)
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :name => self.name,
        :organization_type => self.organization_type,
        :summary_url => Rails.application.routes.url_helpers.organization_path(self),
        :payment_url => Rails.application.routes.url_helpers.payment_organization_path(self),
        :members_url => Rails.application.routes.url_helpers.organization_members_path(:organization_id => self.id),
        :members_import_url => Rails.application.routes.url_helpers.import_v1_organization_members_path(),
        :trial_end_date => self.trial_end_date,
        :trial_remaining_days => self.trial_remaining_days,
        :recommended_subscription_level_id => recommended && recommended.id,
        :locked => self.auto_locked || self.admin_locked,
        :cc_exp_month => self.cc_exp_month,
        :cc_exp_year => self.cc_exp_year,
        :cc_type => self.cc_type,
        :cc_last4 => self.cc_last4,
        :subscription_level_id => subscription ? subscription.subscription_level_id : nil,
        :can_add_project => self.can_add_project?,
        :can_add_member => self.can_add_member?,
        :can_add_attachment => self.can_add_attachment?(1024),
        :total_attachment_size => self.total_attachment_size,
        :subscription_yearly => subscription && subscription.yearly,
        :subscription_price => subscription && subscription.price.to_f,
        :promotion_id => self.promotion_id,
        :promotion_expires_at => self.promotion_expires_at,
        :member_price => self.member_price       
      }
    end
  end
  
  def on_trial?
    subscription = self.subscriptions.active.first
    return (self.trial_end_date && (self.trial_end_date >= Date.today)) && 
    !(subscription && (self.stripe_customer_id || subscription.price.zero? || self.invoice_billing))
  end
  
  def should_auto_lock?
    subscription = self.subscriptions.active.first
    return (
      !self.on_trial? &&
      !(subscription && (self.stripe_customer_id || subscription.price.zero? || self.invoice_billing))
    )
  end
  
  def trial_remaining_days
    today = Date.today
    return self.on_trial? ? (self.trial_end_date-today+1).to_i : nil
  end
    
  def can_add_project?
    subscription = self.subscriptions.active.first
    return !(self.auto_locked || self.admin_locked) && 
      (
        self.on_trial? ||      
        !!(
          (subscription && (subscription.subscription_level.max_projects.nil? || subscription.subscription_level.max_projects > self.projects.count))
        )
      )
  end

  def can_add_member?
    subscription = self.subscriptions.active.first
    return !!(
      self.on_trial? ||
      (subscription && (subscription.subscription_level.max_members.nil? || subscription.subscription_level.max_members > self.organization_members.count))
    )
  end
  
  def can_add_attachment?(bytes)
    subscription = self.subscriptions.active.first
    return !!(
      self.on_trial? ||
      (subscription && (subscription.subscription_level.max_storage_mb.nil? || subscription.subscription_level.max_storage_mb > (self.total_attachment_size / 1048576.0).ceil))
    )
  end
  
  def total_attachment_size
    project_ids = self.projects.collect{|x| x.id}
    Attachment.joins("LEFT JOIN blog_posts ON attachments.item_type = 'BlogPost' AND attachments.item_id = blog_posts.id LEFT JOIN hypotheses ON attachments.item_type = 'Hypothesis' AND attachments.item_id = hypotheses.id").where(["blog_posts.project_id IN (?) OR hypotheses.project_id IN (?)", project_ids, project_ids]).sum("attachments.data_file_size")
  end
      
  def merge_into_organization!(other)
    self.organization_members.each do |organization_member|
      other.organization_members.create!(:user_id => organization_member.user_id, :level => organization_member.level) unless other.organization_members.where(:user_id => organization_member.user_id).count > 0
    end
    
    self.projects.each do |project|
      project.organization = other
      project.save!
    end
    
    self.charges.each do |charge|
      charge.organization = other
      charge.save!
    end
      
    self.reload.destroy
  end
  
  def charge(date, force_billable = true)
    raise if (force_billable && Organization.billable(date).where(:id => self.id).count.zero?)
        
    subscription = self.subscriptions.active(date-1).first || self.subscriptions.active(date).first
    comments = "#{self.to_param}, #{subscription.subscription_level} plan"
    
    billing_start = (date.end_of_month == subscription.start_date.end_of_month) ? subscription.start_date : date
    
    if (subscription.yearly)
      normal_start_date = billing_start.beginning_of_year
      end_date = date.end_of_year      
      comments << ", #{number_to_currency(subscription.price)}/year"
    else
      normal_start_date = billing_start.beginning_of_month
      end_date = date.end_of_month      
      comments << ", #{number_to_currency(subscription.price)}/month"      
    end
        
    ratio = (end_date - billing_start + 1) / (end_date - normal_start_date + 1)
    amount = (subscription.price * ratio).round(2).to_f    
    previous_amount = self.charges.where(:period_end => end_date).inject(0) {|sum,x| sum + x.amount}
    return nil if previous_amount >= amount
    
    comments << ", #{billing_start} to #{end_date} = #{number_to_currency(amount)}"
    
    if (previous_amount > 0)
      amount -= previous_amount
      comments << " - #{number_to_currency(previous_amount)} = #{number_to_currency(amount)}"
    end      
    
    return self.charges.build(
      :amount => amount,
      :period_start => billing_start,
      :period_end => end_date,
      :comments => comments
    )
  end
  
  def reset_cc!
    self.stripe_customer_id = nil
    self.cc_last4 = nil
    self.cc_exp_year = nil
    self.cc_exp_month = nil
    self.cc_type = nil
    self.cc_user_id = nil
    self.auto_locked = self.should_auto_lock?
    self.save!
  end
end