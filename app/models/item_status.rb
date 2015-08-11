class ItemStatus < ActiveRecord::Base
  belongs_to :canvas_item

  @@statuses = {}

  def self.[](value)
    @@statuses[value] ||= find_by_status(value).id
  end
  
  def to_s
    self.status
  end
  
  def self.cached_find_by_status(status)
    Rails.cache.fetch("#{self.name}.#{status.normalize}".slice(0,200)) do
      self.find_by_status(status)
    end        
  end
  
  after_commit do |obj|
    Rails.cache.delete("#{obj.class.name}.#{obj.status.normalize}".slice(0,200))
    true
  end
  
end
