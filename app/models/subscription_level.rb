class SubscriptionLevel < ActiveRecord::Base
  
  acts_as_audited
  
  include NamedEntity
  
  scope(:available, where(:available => true))
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/json") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :name => self.name,
        :tagline => self.tagline,
        :monthly_price => self.monthly_price && self.monthly_price.to_f.round(2),
        :yearly_price => self.yearly_price && self.yearly_price.to_f.round(2),
        :max_projects => self.max_projects,
        :max_members => self.max_members,
        :max_storage_mb => self.max_storage_mb,
        :support_email => self.support_email,
        :support_chat => self.support_chat,
        :support_phone => self.support_phone
      }
    end
  end
  
  def SubscriptionLevel.recommended(organization)
    SubscriptionLevel.available.
      where(["max_projects IS NULL OR max_projects >= ?", organization.projects.count]).
      where(["max_members IS NULL OR max_members >= ?", organization.organization_members.count]).
      where(["max_storage_mb IS NULL OR max_storage_mb >= ?", (organization.total_attachment_size / 1048576.0).ceil]).
      order("monthly_price ASC").
      first
  end
end