class Member < ActiveRecord::Base
  has_many :attachments, :dependent => :destroy
  belongs_to :user, :touch => true
  belongs_to :project, :touch => true
  has_many :member_blog_post_views, :dependent => :destroy
  has_many :user_activities
  has_many :blog_posts, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :tasks, :class_name => "ProjectTask", :foreign_key => "assigned_to_member_id"

  validates_associated :user

  #TODO: this causes a stack level too deep error, but I think it would be more correct to have it
  #validates_associated :project

  validates_presence_of :level, :role_name
  
  validates_uniqueness_of :user_id, :scope => :project_id

  attr_accessible :level, :description, :activated, :project_attributes, :user_id, :project_id, :is_owner, :role_name, :notify_hypotheses, :notify_hypotheses_validated, :notify_interviews, :notify_updates, :daily_summary, :weekly_summary, :accessed_at, :display_plan_done, :display_plan_in_progress, :display_plan_todo, :plan_done_sort, :notify_goals
  
  attr_accessor :deactivated_flag
  
  scope :joined_project, lambda { |project|
    where("activated = true AND project_id=?", project.id)
  }
  
  scope :active, where(:activated => true)
  scope :admin, where(:level => "Owner")
  
  scope(
    :deletable,
    select("members.*")
      .joins("
        LEFT JOIN attachments ON members.id = attachments.member_id
        LEFT JOIN blog_posts ON members.id = blog_posts.member_id
        LEFT JOIN comments ON members.id = comments.member_id
      ")
      .where("activated = 'f'")
      .group("members.id")
      .having("
        COUNT(attachments.*) = 0
        AND COUNT(blog_posts.*) = 0
        AND COUNT(comments.*) = 0
      ")
  )
  
  acts_as_audited :associated_with => :project, :except => [
    :accessed_at
  ]
  
  validate do |member|
    if (member.activated_changed? && !member.activated && member.last_admin?)
      member.errors[:base] << "Sorry, you're currently the only Owner on this project so you cannot remove yourself. If you'd like to leave this project, please give another member Owner permissions, then try to remove yourself again."
      return false
    end
    return true
  end
  
  before_create do |member|
    member.default_notifications
    member.accessed_at = Time.zone.now
    true
  end
  
  after_create do |member|
    if (!member.project.goal_invite_completed && member.project.members.count > 1)
      member.project.goal_invite_completed = true
      member.project.save!
    end
    true
  end
  
  before_save do |member|
    error = false
    
    if (member.new_record? || member.activated_changed?)
      if member.activated
        member.assign_join_code if member.join_code.nil?
        
        # create org member for project member
        unless (member.project.organization.organization_members.where(:user_id => member.user_id).count > 0)
          organization_member = member.project.organization.organization_members.build(:user_id => member.user_id, :level => (member.project.organization.organization_members.count.zero? ? "Admin" : "Normal"))
          error = !organization_member.save
        end
        
      else
        # de-assign assigned tasks
        member.tasks.find_each {|x| x.update_attributes!(:assigned_to_member_id => nil)}

        member.deactivated_flag = true
      end
    end
    
    return !error
  end
  
  after_save do |member|
    if (member.deactivated_flag)
      # if organization member was not an admin and was only a member of this project, remove from the organization
      if (organization_member = member.user.organization_members.where(:organization_id => member.project.organization_id).first)
        unless (
          (Member.joins("JOIN projects ON members.project_id = projects.id").where(["members.user_id = ? AND projects.organization_id = ?", member.user_id, organization_member.organization_id]).active.count > 1) || 
          (
            (organization_member.level == "Admin") &&
            organization_member.organization.organization_members.where(["level = 'Admin' AND id <> ?", organization_member.id]).count.zero?
          )
        )
          organization_member.destroy
        end
      end
    end
    true
  end
      
  include ImportExport
  
  # def Member.import(hash, user, project)
  #   unless (m = Member.where(:user_id => user.id, :project_id => project.id).first)
  #     m = super(hash)
  #     m.user = user
  #     m.project = project
  #   end
  #   return m
  # end
  
  def export
    hash = super
    hash["relationships"] = {
      "user_id" => self.user_id, 
      "project_id" => self.project_id
    }
    return hash
  end
  
  def to_s
    "#{project} / #{user}"
  end

  def deactivate
    self.activated = false
    return self.save
  end

  def joined_and_active?
    self.activated
  end
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      ability = Ability.new(self.user)
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :role => self.role_name,
        :level => self.level,
        :active => self.activated,
        :can_comment => ability.can?(:create, Comment.new(:blog_post => project.blog_posts.build)),
        :can_manage_hypotheses => ability.can?(:manage, self.project.hypotheses.build),
        :can_manage_journal => ability.can?(:manage, self.project.blog_posts.build),
        :can_manage_canvas => ability.can?(:manage, self.project.canvas_items.build),
        :can_manage_members => ability.can?(:manage, self.project.members.build),
        :can_manage_project => ability.can?(:manage, self.project),
        :can_manage_tasks => ability.can?(:manage, self.project.tasks.build),
        :display_plan_todo => self.display_plan_todo,
        :display_plan_in_progress => self.display_plan_in_progress,
        :display_plan_done => self.display_plan_done,
        :plan_done_sort => self.plan_done_sort,
        :notify_goals => self.notify_goals,
        :notify_hypotheses => self.notify_hypotheses,
        :notify_hypotheses_validated => self.notify_hypotheses_validated,
        :notify_updates => self.notify_updates,
        :notify_interviews => self.notify_interviews,
        :daily_summary => self.daily_summary,
        :weekly_summary => self.weekly_summary,
        :project_id => self.project_id,
        :user_id => self.user_id
      }
    end
  end
  
  def last_admin?
    return (self.level == "Owner" && self.project.members.active.where(:level => "Owner").count < 2)
  end

  LETTERS_AND_NUMBERS = ('A'..'Z').to_a + ("0".."9").to_a

  def assign_join_code
    unless is_owner?
      self.join_code = (1..9).collect { LETTERS_AND_NUMBERS[rand 36] }.join
    end
  end
  
  def default_notifications
    # Default in DB is all enabled - here we'll disable some
    case self.role_name
    when /^(Manager)/
      self.notify_hypotheses = false
      self.notify_hypotheses_validated = false
      self.notify_interviews = false
      self.notify_updates = false
    end
  end
end
