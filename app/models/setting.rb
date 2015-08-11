class Setting < ActiveRecord::Base
  has_one :attachment, :as => :item, :dependent => :destroy
  belongs_to :user, :touch => true

  acts_as_audited
    
end
