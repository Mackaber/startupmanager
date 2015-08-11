class UserActivity < ActiveRecord::Base

  belongs_to :user
  belongs_to :member

  before_save :truncate_description

  def truncate_description
    self.description = self.description[0, 250]
  end

end
