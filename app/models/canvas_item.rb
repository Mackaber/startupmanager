class CanvasItem < ActiveRecord::Base
  attr_accessor :delta_deleted, :delta_changed, :delta_added

  belongs_to :box
  belongs_to :hypothesis
  belongs_to :item_status
  belongs_to :project, :touch => true
  has_many :descendants, :class_name => "CanvasItem", :foreign_key => "original_id"
  belongs_to :original, :class_name => "CanvasItem", :foreign_key => "original_id"
  
  validates_presence_of :box_id, :project_id, :item_status_id, :text

  before_save :truncate_text
  
  attr_writer :include_in_plan
  attr_accessor :set_original_flag
  
  validates_inclusion_of :display_color, :in => %w( red yellow blue green purple )
  
  scope(:active, where("canvas_items.inactive_at IS NULL AND canvas_items.deleted = false"))
  scope(:items_for_week, lambda do |date|
    t = (date.beginning_of_week+7).midnight
    where(:deleted => false).
    where(["inactive_at IS NULL OR inactive_at >= ?", t]).
    where(["created_at < ?", t])    
  end)

  acts_as_audited :associated_with => :project
  
  include ImportExport
  
  before_save do |canvas_item|
    case canvas_item.instance_variable_get(:@include_in_plan)
    when false
      if (canvas_item.hypothesis_id)
        canvas_item.hypothesis.destroy
        canvas_item.hypothesis_id = nil
      end
    when true
      canvas_item.include_in_plan = nil
      # FIXME: workaround for duplicate hypotheses being created
      if canvas_item.project.hypotheses.where(:title => canvas_item.text).count.zero?
        unless canvas_item.hypothesis
          canvas_item.hypothesis = Hypothesis.new(:project => canvas_item.project) 
          canvas_item.hypothesis.notify_flag = false
          canvas_item.hypothesis.item_status = ((canvas_item.item_status.status == "unknown") ? nil : canvas_item.item_status)
        end
        canvas_item.hypothesis.title = canvas_item.text
        canvas_item.hypothesis.description = canvas_item.description
        canvas_item.hypothesis.save! if canvas_item.hypothesis.changed?
        canvas_item.save! if canvas_item.changed?
      end
    end
    true
  end
  
  after_create do |canvas_item|
    if canvas_item.original_id.nil?
      canvas_item.original_id = canvas_item.id
      canvas_item.added = true
      canvas_item.save!
      
      unless (canvas_item.project.goal_canvas_completed)
        canvas_item.project.goal_canvas_completed = true
        canvas_item.project.save!
      end
    else
      CanvasItem.where(["canvas_items.original_id = ? AND canvas_items.id < ? AND canvas_items.inactive_at IS NULL", canvas_item.original_id, canvas_item.id]).find_each do |old_item|
        old_item.inactive_at = Time.zone.now
        # old_item.z = nil
        old_item.hypothesis_id = nil
        old_item.save! if old_item.changed?
      end
    end         
    
    if (canvas_item.hypothesis)
      canvas_item.hypothesis.update_attributes!(:updated_at => canvas_item.created_at)
    end
    
    true
  end
    
  def export
    hash = super
    hash["relationships"] = {
      "box_id" => self.box_id, 
      "hypothesis_id" => self.hypothesis_id, 
      "item_status_id" => self.item_status_id, 
      "project_id" => self.project_id
    }
    return hash
  end
  
  # def CanvasItem.import(hash, box, item_status, project)
  #   ci = super(hash)
  #   ci.box = box
  #   ci.item_status = item_status
  #   ci.project = project
  #   return ci
  # end
  
  def to_s
    return text
  end

  def create_updated(attrs={})
    clone_obj = self.dup
    clone_obj.added = false
    clone_obj.deleted = false
    clone_obj.updated = false
    clone_obj.inactive_at = nil
    clone_obj.attributes = attrs
    clone_obj.z = nil if clone_obj.deleted
    logger.debug("CI #{clone_obj.inspect}")
    clone_obj.save
    return clone_obj    
  end 

  def truncate_text
    self.text = self.text[0, 140]
  end
  private :truncate_text
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :project_id => self.project_id,
        :original_id => self.original_id,
        :category => self.category,
        :title => self.text,
        :description => self.description,
        :status => self.status,
        :created_at => self.created_at,
        :display_color => self.display_color,
        :inactive_at => self.inactive_at,
        :added => self.added,
        :updated => self.updated,
        :deleted => self.deleted,
        :include_in_plan => self.include_in_plan,
        :x => self.x,
        :y => self.y,
        :z => self.z
      }
    end
  end
  
  def category
    return "#{self.box}"
  end
  
  def category=(value)
    if value.blank?
      self.box = nil
    else
      self.box = Box.find_by_name(value)
    end
  end  
  
  def status
    return "#{self.item_status}"
  end

  def status=(value)
    if value.blank?
      self.item_status = nil
    else
      self.item_status = ItemStatus.find_by_status(value)
    end
  end 
  
  def include_in_plan
    !self.hypothesis_id.nil?
  end
      
end
