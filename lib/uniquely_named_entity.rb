# encoding: utf-8
module UniquelyNamedEntity
  
  def self.included(base)
    base.class_eval do
      include(NamedEntity)
      validates_uniqueness_of :name
    end
  end
    
end