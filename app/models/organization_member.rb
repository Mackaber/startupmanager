class OrganizationMember < ActiveRecord::Base
  
  belongs_to :organization, :touch => true
  belongs_to :user, :touch => true
  
  acts_as_audited
  
  validates_presence_of :organization
  validates_presence_of :user
  validates_inclusion_of :level, :in => %w( Admin Normal )
  
  before_validation do |organization_member|
    organization_member.level ||= (organization_member.organization.organization_members.count.zero? ? "Admin" : "Normal")
  end
  
  validate do |organization_member|
    if (organization_member.level_changed? && organization_member.level_was == "Admin" && organization_member.organization.organization_members.where(["level = 'Admin' AND id <> ?", organization_member.id]).count.zero?)
      member.errors[:base] << "Sorry, you're currently the only Admin on this organization so you cannot remove yourself. If you'd like to leave this organization, please give another member Admin permissions, then try to remove yourself again."
    end
    
    if (organization_member.new_record? && !organization_member.organization.can_add_member?)
      organization_member.errors.add(:base, "Organization #{organization_member.organization} has the maximum number of members and needs to be upgraded to a higher subscription level.")
    end
  end
  
  after_create do |organization_member|
    organization_member.assign_payment_code! if organization_member.organization.member_price && organization_member.level != "Admin"
  end
    
  after_destroy do |organization_member|
    Member.includes(:project).where(["projects.organization_id = ? AND members.user_id = ?", organization_member.organization_id, organization_member.user_id]).find_each do |member|
      member.deactivate
    end
  end
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :level => self.level,
        :organization_id => self.organization_id,
        :user_id => self.user_id,
        :payment_code => self.payment_code,
        :paid_at => self.paid_at
      }
    end
  end
    
  LETTERS_AND_NUMBERS = ('A'..'Z').to_a + ("0".."9").to_a
  
  # yes, there's a race condition here. move along.
  def assign_payment_code!
    while (self.payment_code.nil? || Project.find_by_payment_code(self.payment_code))
      self.payment_code = (1..9).collect { LETTERS_AND_NUMBERS[rand 36] }.join
    end
    self.save!
  end
  
  def to_s
    "#{self.user.email} / #{self.organization}"
  end
  
  def reset_cc!
    self.stripe_customer_id = nil
    self.cc_last4 = nil
    self.cc_exp_year = nil
    self.cc_exp_month = nil
    self.cc_type = nil
    self.stripe_charge_id = nil
    self.save!
  end
  
  def process_payment!
    begin
      if (stripe_charge = Stripe::Charge.create(
        :amount => (self.organization.member_price * 100).to_i,
        :currency => "usd",
        :customer => self.stripe_customer_id,
        :description => self.to_param
      ))
        Rails.logger.debug("STRIPE #{stripe_charge.inspect}")
        self.update_attributes!(:stripe_charge_id => stripe_charge.id)
      end
    rescue Stripe::CardError => error
      self.reset_cc!
    end
  end
  
end