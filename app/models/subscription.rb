class Subscription < ActiveRecord::Base
  
  belongs_to :organization, :touch => true
  belongs_to :subscription_level
  
  validates_presence_of :organization
  validates_presence_of :subscription_level
  validates_presence_of :start_date
  validates_presence_of :price
  
  before_create do |subscription|
    subscription.organization.subscriptions.where(:end_date => nil).each do |other_subscription|
      other_subscription.update_attributes!(:end_date => Date.today) unless other_subscription == subscription
    end
  end
  
  acts_as_audited
  
  scope(
    :active, 
    lambda do |date = Date.today|
      where(["start_date <= ? AND (end_date IS NULL OR end_date >= ?)", date, date])
    end
  )

  def to_s
    "#{self.subscription_level} #{self.price.to_f.round(2)}/#{self.yearly ? 'year' : 'month'}"
  end
  
end