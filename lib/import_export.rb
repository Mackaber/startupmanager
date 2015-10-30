# encoding: utf-8
module ImportExport
  
  def self.included(base)
    base.class_eval do
      extend ImportExport::ClassMethods
    end
  end
  
  module ClassMethods  
    def import(hash)
      obj = self.new
      hash["attributes"].each {|k, v| obj.send("#{k}=", v)}
      return obj
    end
  end
   
  def export
    hash = {}
    hash["type"] = self.class.name
    hash["id"] = self.id
    hash["attributes"] = self.attributes
    # hash["attributes"].delete_if {|k,v| (k == "id") || (k =~ /_id$/)}
    return hash
  end
  
end