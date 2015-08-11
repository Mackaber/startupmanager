module ActiveRecord
  
  class Base
    
    attr_accessor :flush_flag_id
    
    def self.cached_find_by_id(id)
      Rails.cache.fetch("#{self.name}.#{id}") do
        self.find_by_id(id)
      end        
    end
    
    def flush_cache_id
      Rails.cache.delete("#{self.class.name}.#{self.id}")
    end
    
    before_save do |obj|
      flush_flag_id = should_flush?
    end
      
    before_destroy do |obj|
      flush_flag_id = true
    end
    
    after_commit do |obj|
      obj.flush_cache_id if flush_flag_id
      true
    end
    
    def should_flush?
      true
    end
        
  end
  
end
