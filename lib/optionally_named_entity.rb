# encoding: utf-8
module OptionallyNamedEntity
  def self.included(base)
    base.class_eval do
      scope(:by_name, :order => "name ASC")
      
      def self.cached_find_by_name(name)
        Rails.cache.fetch("#{self.name}.#{name.normalize}".slice(0,200)) do
          self.find_by_name(name)
        end        
      end
      
      after_commit do |obj|
        Rails.cache.delete("#{obj.class.name}.#{obj.name.normalize}".slice(0,200))
        true
      end
      
    end    
  end
  
  def to_s
    self.name
  end  
end