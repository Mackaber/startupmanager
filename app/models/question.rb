class Question < ActiveRecord::Base
    
  belongs_to :hypothesis, :touch => true
  belongs_to :project
  
  # validates_presence_of :hypothesis
  
  include Sanitized
  
  acts_as_audited :associated_with => :project
  
  before_create do |model|
    model.project ||= model.hypothesis.project if model.hypothesis
    
    model.insert_at(1) unless model.position
    true
  end
  
  before_destroy do |model|
    model.remove_from_list(false)
    true
  end
  
  include ImportExport  
  
  def export
    hash = super
    hash["relationships"] = {
      "hypothesis_id" => self.hypothesis_id,
      "project_id" => self.project_id
    }
    return hash
  end    
  
  # def Question.import(hash, member, project)
  #   bp = super(hash)    
  #   bp.member = member
  #   bp.project = project    
  #   return bp
  # end  
    
  def to_s
    return self.title
  end
    
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :title => self.title,
        :position => self.position,
        :hypothesis_id => self.hypothesis_id,
        :created_at => self.created_at
      }
    end
  end
  
  def remove_from_list(save_self = true)    
    return unless self.position
    
    self.hypothesis.questions.where("position > ?", self.position).each{|x| x.update_attributes!(:position => x.position-1)}
    self.update_attributes!(:position => nil) if (save_self)
  end
  
  def insert_at(pos)
    self.hypothesis.questions.where("position >= ?", pos).each{|x| x.update_attributes!(:position => x.position+1)}
    self.position = pos
  end
  
end