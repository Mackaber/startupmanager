class Experiment < ActiveRecord::Base

  belongs_to :hypothesis, :touch => true
  belongs_to :item_status
  belongs_to :project
    
  include Sanitized

  acts_as_audited :associated_with => :project
  
  validates_presence_of :title
  
  # validate do |experiment|
  #   experiment.errors[:base] << ("must be associated with something") unless (experiment.project || experiment.hypothesis)
  #   true
  # end

  before_create do |experiment|
    experiment.project ||= experiment.hypothesis.project if experiment.hypothesis
    true
  end

  before_save do |model|
    if (model.item_status_id_changed?)
      if (model.complete?)
        model.completed_at = Time.now
      else
        model.completed_at = nil
      end
    end
    true
  end

  before_create do |model|
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
      "item_status_id" => self.item_status_id,
      "project_id" => self.project_id
    }
    return hash
  end    
  
  # def Experiment.import(hash, member, project)
  #   bp = super(hash)    
  #   bp.member = member
  #   bp.project = project    
  #   return bp
  # end
  
  def status_summary(start_at, end_at)
    changes = self.audits.where(["audits.created_at BETWEEN ? AND ?", start_at, end_at]).descending
    if (changes.select{|x| x.action == "create"}.first)
      return "New"
    elsif (changes.select{|x| x.new_attributes.has_key?("item_status_id")}.first)
      return case self.item_status
      when ItemStatus.cached_find_by_status("completed")
        "Completed"
      when ItemStatus.cached_find_by_status("started")
        "Started"
      else
        "Updated"
      end
    else
      return "Updated"
    end
  end
    
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :project_id => self.project_id,
        :hypothesis_id => self.hypothesis_id,
        :created_at => self.created_at,
        :completed_at => self.completed_at,
        :position => self.position,
        :title => self.title,
        :status => self.status,
        :success_criteria => self.success_criteria,
        :start_date => self.start_date,
        :end_date => self.end_date
      }
    end
  end

  def to_s
    return self.title
  end
  
  def status
    return "#{self.item_status}"
  end

  def status=(value)
    if value == ''
      self.item_status = nil
    else
      self.item_status = ItemStatus.find_by_status(value)
    end
  end
  
  def complete?
    return [ItemStatus.cached_find_by_status("completed")].include?(self.item_status)
  end
  
  def remove_from_list(save_self = true)
    return unless self.position
    
    self.hypothesis.experiments.where("position > ?", self.position).each{|x| x.update_attributes!(:position => x.position-1)}
    self.hypothesis.tasks.where("position > ?", self.position).each{|x| x.update_attributes!(:position => x.position-1)}
    
    self.update_attributes!(:position => nil) if (save_self)
  end

  def insert_at(pos)
    self.hypothesis.experiments.where("position >= ?", pos).each{|x| x.update_attributes!(:position => x.position+1)}
    self.hypothesis.tasks.where("position >= ?", pos).each{|x| x.update_attributes!(:position => x.position+1)}
    self.position = pos
  end

end
