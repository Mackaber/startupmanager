require 'mime/types'

class Ckeditor::Asset < ActiveRecord::Base
  include Ckeditor::Orm::ActiveRecord::AssetBase

  attr_accessible :data, :assetable_type, :assetable_id, :assetable
  
  include ImportExport

  acts_as_audited
  
  def export
    hash = super
    hash["attributes"].delete("assetable_type")
    hash["relationships"] = {}
    case self.assetable_type
    when "BlogPost"
      hash["relationships"]["blog_post_id"] = self.assetable_id
    end
    return hash
  end 
   
  def self.import(hash, assetable)
    a = super(hash)
    a.assetable = assetable
    return a
  end
  
end
