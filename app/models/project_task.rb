# "Task" is a reserved word, you can't even namespace it... [sigh]
class ProjectTask < ActiveRecord::Base
  
  self.table_name = "tasks"
  
  belongs_to :hypothesis, :touch => true
  belongs_to :project, :touch => true
  belongs_to :assigned_to_member, :class_name => "Member", :foreign_key => "assigned_to_member_id"
  
  # validates_presence_of :project
  validates_presence_of :title
  
  attr_accessor :mail_flag
  
  include Sanitized
      
  acts_as_audited :associated_with => :project
      
  before_create do |project_task|  
    project_task.project ||= project_task.hypothesis.project if project_task.hypothesis
    true
  end
  
  before_save do |project_task|
    if project_task.assigned_to_member_id_changed? && project_task.assigned_to_member_id && (project_task.assigned_to_member_id != project_task.audits.last.user.members.where(:project_id => project_task.project_id).first.id)
      project_task.mail_flag = true
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
    
  after_commit do |project_task|
    # Only email on task assignment if the assignee has update notifications off
    if (project_task.mail_flag)
      Resque.enqueue(Jobs::Notify::TaskAssigned, project_task.id, project_task.audits.last.user_id)
    end
    true
  end
  
  include ImportExport  
  
  def export
    hash = super
    hash["relationships"] = {
      "hypothesis_id" => self.hypothesis_id,
      "project_id" => self.project_id,
      "assigned_to_member_id" => self.assigned_to_member_id
    }
    return hash
  end    
  
  # def ProjectTask.import(hash, member, project)
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
        :type => "task",
        :id => self.id,
        :project_id => self.project_id,
        :hypothesis_id => self.hypothesis_id,
        :created_at => self.created_at,
        :completed_at => self.completed_at,
        :position => self.position,
        :title => self.title,
        :description => self.description,
        :due_date => self.due_date,
        :assigned_to_member_id => self.assigned_to_member_id
      }
    end
  end
  
  def url
    "#{Rails.application.routes.url_helpers.project_tasks_url(self.project, Rails.application.config.action_mailer.default_url_options)}#tasks/#{self.id}"
  end
  
  def remove_from_list(save_self = true)    
    return unless self.position    
    self.project.tasks.where("position > ?", self.position).each{|x| x.update_attributes!(:position => x.position-1)}
    self.update_attributes!(:position => nil) if (save_self)
  end
  
  def insert_at(pos)
    self.project.tasks.where("position >= ?", pos).each{|x| x.update_attributes!(:position => x.position+1)}
    self.position = pos
  end
  
end