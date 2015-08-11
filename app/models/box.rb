class Box < ActiveRecord::Base
  
  def to_s
    self.name
  end
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :value => self.name,
        :label => self.label,
        :description => self.description,
        :startup_label => self.startup_label,
        :startup_description => self.startup_description
      }
    end
  end
  
end
