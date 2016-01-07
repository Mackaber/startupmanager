class Hypothesis < ActiveRecord::Base

  after_update :save_hash

  has_many :attachments, :as => :item, :dependent => :destroy
  has_one :canvas_item
  has_many :comments, :dependent => :destroy
  has_many :experiments, :dependent => :destroy
  belongs_to :hypothesis, :touch => true
  has_many :hypotheses
  belongs_to :item_status
  belongs_to :project, :touch => true
  has_many :questions, :dependent => :destroy
  has_many :tasks, :class_name => "ProjectTask", :dependent => :destroy

  validates_presence_of :title
  validates_presence_of :project

  accepts_nested_attributes_for :questions, :allow_destroy => true
  accepts_nested_attributes_for :experiments, :allow_destroy => true
  accepts_nested_attributes_for :tasks, :allow_destroy => true

  attr_accessor :notify_flag

  include Sanitized

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

  # def Hypothesis.import(hash, member, project)
  #   bp = super(hash)    
  #   bp.member = member
  #   bp.project = project    
  #   return bp
  # end

  acts_as_audited except: :json_hash
  acts_as_audited :associated_with => :project

  validate do |hypothesis|
    if hypothesis.id && hypothesis.id == hypothesis.hypothesis_id
      hypothesis.errors.add(:hypothesis_id, "can't refer to self")
    end
  end

  before_create do |hypothesis|
    if (hypothesis.notify_flag.nil?)
      if (hypothesis.title_changed? || hypothesis.description_changed? || (hypothesis.item_status_id_changed? && hypothesis.item_status && hypothesis.item_status.status != "started"))
        hypothesis.notify_flag = (hypothesis.new_record? ? :new : :updated) if hypothesis.notify_flag.nil?
      end
    end

    hypothesis.insert_at(1) unless hypothesis.position

    true
  end

  after_create do |hypothesis|
    unless hypothesis.canvas_item || hypothesis.project.goal_create_hypothesis_completed
      hypothesis.project.goal_create_hypothesis_completed = true
      hypothesis.project.save!
    end
    true
  end

  before_update do |hypothesis|
    if (hypothesis.notify_flag.nil?)
      if (hypothesis.item_status_id_changed? && hypothesis.item_status && hypothesis.item_status.status == "valid")
        hypothesis.notify_flag = :validated
      end
    end
    true
  end

  after_update do |hypothesis|
    if (!hypothesis.project.goal_test_hypothesis_completed && hypothesis.item_status)
      hypothesis.project.goal_test_hypothesis_completed = true
    end
    if (!hypothesis.project.goal_validate_hypothesis_completed && hypothesis.complete?)
      hypothesis.project.goal_validate_hypothesis_completed = true
    end
    hypothesis.project.save! if hypothesis.project.changed?
    true
  end


  before_save do |hypothesis|
    if (hypothesis.title_changed? || hypothesis.description_changed? || (hypothesis.item_status_id_changed? && hypothesis.item_status && hypothesis.item_status.status != "started"))
      if (hypothesis.canvas_item)
        hypothesis.canvas_item = hypothesis.canvas_item.create_updated(
            :text => hypothesis.title,
            :description => hypothesis.description,
            :item_status => ((hypothesis.item_status.nil? || hypothesis.item_status.status == "started") ? ItemStatus.find_by_status("unknown") : hypothesis.item_status),
            :updated => true
        )
      end
    end

    if (hypothesis.item_status_id_changed?)
      if (hypothesis.item_status_id)
        hypothesis.completed_at = Time.now
      else
        hypothesis.completed_at = nil
      end

      hypothesis.remove_from_list(false)
      hypothesis.insert_at(-1)
    end

    true
  end

  before_destroy do |model|
    model.remove_from_list(false)
    true
  end

  after_commit do |hypothesis|
    if (hypothesis.notify_flag == :validated)
      Resque.enqueue(Jobs::Notify::HypothesisValidated, hypothesis.id)
    elsif (hypothesis.notify_flag)
      Resque.enqueue(Jobs::Notify::HypothesisUpdated, hypothesis.id, hypothesis.notify_flag == :new)
    end
    true
  end

  scope(:top_level, where(:hypothesis_id => nil))
  scope(:non_canvas, joins("LEFT JOIN canvas_items ON hypotheses.id = canvas_items.hypothesis_id").where("canvas_items.id IS NULL"))

  def complete?
    return [ItemStatus.cached_find_by_status("valid"), ItemStatus.cached_find_by_status("invalid"), ItemStatus.cached_find_by_status("unknown")].include?(self.item_status)
  end

  # To HASH functions

  def save_hash
    update_column(:json_hash, get_hash.to_json)
  end

  def get_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      m = self.created_by_member
      {
          :type => self.class.name.underscore,
          :id => self.id,
          :project_id => self.project_id,
          :created_at => self.created_at,
          :updated_at => self.updated_at,
          :created_by_member_id => m ? m.id : nil,
          :completed_at => self.completed_at,
          :completed_reason => self.completed_reason,
          :description => self.description,
          :hypothesis_id => self.hypothesis_id,
          :position => self.position,
          :title => self.title,
          :status => self.status,
          :canvas_box => (self.canvas_item && self.canvas_item.box) ? self.canvas_item.box.label : nil
      }
    end
  end

  def to_hash
    JSON.parse(json_hash ? json_hash : "{}")
  end

  # def to_hash
  #   Rails.cache.fetch(self.cache_key + "/hash") do
  #     m = self.created_by_member
  #     {
  #       :type => self.class.name.underscore,
  #       :id => self.id,
  #       :project_id => self.project_id,
  #       :created_at => self.created_at,
  #       :updated_at => self.updated_at,
  #       :created_by_member_id => m ? m.id : nil,
  #       :completed_at => self.completed_at,
  #       :completed_reason => self.completed_reason,
  #       :description => self.description,
  #       :hypothesis_id => self.hypothesis_id,
  #       :position => self.position,
  #       :title => self.title,
  #       :status => self.status,
  #       :canvas_box => (self.canvas_item && self.canvas_item.box) ? self.canvas_item.box.label : nil
  #     }
  #   end
  # end

  def created_by_member
    a = self.audits.where("user_id IS NOT NULL").order("created_at").select{|x| x.user.members.where(:project_id => self.project_id).first}.first
    a = a ? a.user.members.where(:project_id => self.project_id).first : nil
  end

  def to_s
    return self.title
  end

  def status_summary(start_at, end_at)
    changes = self.audits.where(["audits.created_at BETWEEN ? AND ?", start_at, end_at]).descending
    if (changes.select{|x| x.action == "create"}.first)
      return "New"
    elsif (changes.select{|x| x.new_attributes.has_key?("item_status_id")}.first)
      return case self.item_status
               when ItemStatus.cached_find_by_status("invalid")
                 "Invalidated"
               when ItemStatus.cached_find_by_status("started")
                 "Started"
               when ItemStatus.cached_find_by_status("valid")
                 "Validated"
               when ItemStatus.cached_find_by_status("unknown")
                 "Unknown"
               else
                 "Updated"
             end
    else
      return "Updated"
    end
  end

  def url
    "#{Rails.application.routes.url_helpers.project_url(self.project, Rails.application.config.action_mailer.default_url_options)}#hypothesis/#{self.id}"
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

  def remove_from_list(save_self = true)
    return unless self.position

    if (self.hypothesis)
      self.hypothesis.hypotheses.where("position > ?", self.position).each{|x| x.update_attributes!(:position => x.position-1)}
    else
      self.project.hypotheses.top_level.where("position > ?", self.position).each{|x| x.update_attributes!(:position => x.position-1)}
    end

    # move children into position occupied by self
    if (!save_self)
      self.hypotheses.sort_by{|x| -x.position}.each do |child|
        child.hypothesis = nil
        child.insert_at(self.position)
      end
    end

    # remove self from list
    self.update_attributes!(:position => nil) if (save_self)
  end

  def insert_at(pos)
    if (pos == -1)
      if (self.hypothesis)
        pos = [0, self.hypothesis.hypotheses.maximum(:position)].select{|x| x}.max+1
      else
        pos = [0, self.project.hypotheses.top_level.maximum(:position)].select{|x| x}.max+1
      end
    end

    if (self.hypothesis)
      self.hypothesis.hypotheses.where("position >= ?", pos).each{|x| x.update_attributes!(:position => x.position+1)}
    else
      self.project.hypotheses.top_level.where("position >= ?", pos).each{|x| x.update_attributes!(:position => x.position+1)}
    end
    self.position = pos
  end
end
