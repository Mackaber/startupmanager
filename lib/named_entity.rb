# encoding: utf-8
module NamedEntity
  
  def self.included(base)
    base.class_eval do
      include(OptionallyNamedEntity)
      validates_presence_of :name
    end
  end
    
end