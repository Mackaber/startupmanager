class Charge < ActiveRecord::Base
  
  belongs_to :organization, :touch => true
  
  validates_presence_of :amount
  validates_presence_of :period_start
  validates_presence_of :period_end
  
  attr_accessor :notify_flag
  
  acts_as_audited
  
  before_update do |charge|
    charge.notify_flag = true if (charge.stripe_charge_id_was.nil? && charge.stripe_charge_id)
  end
  
  after_commit do |charge|
    Resque.enqueue(Jobs::Notify::NewCharge, charge.id) if (charge.notify_flag && charge.organization.cc_user_id)
    true
  end
  
  scope(:outstanding, where(:stripe_charge_id => nil))
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :organization_id => self.organization_id,
        :period_start => self.period_start,
        :period_end => self.period_end,
        :comments => self.comments,
        :amount => self.amount.to_f,
        :created_at => self.created_at
      }
    end
  end
    
end