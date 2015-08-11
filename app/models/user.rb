class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, #REMOVED 2011-12-23 :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :members_attributes, :setting_attributes
  attr_accessor :send_welcome_flag

  has_many :blog_posts, :through => :members
  has_many :members
  has_many :organization_members, :dependent => :destroy
  has_many :organizations, :through => :organization_members
  has_many :projects, :through => :members
  has_many :user_activities
  has_one :setting, :dependent => :destroy
  
  accepts_nested_attributes_for :organizations
  attr_accessible :organizations_attributes
  validates_associated :organizations

  accepts_nested_attributes_for :setting
  attr_accessible :setting_attributes

  validates_presence_of :name

  after_create :create_associated_setting

  include ImportExport
  
  # for image_path in to_hash...
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper
           
  # make sure this FOLLOWS attr_accessible
  acts_as_audited :except => [
    :password,
    :password_confirmation,
    :remember_me,
    :members_attributes,
    :setting_attributes,
    :encrypted_password,
    :reset_password_token,
    :reset_password_sent_at,
    :remember_created_at,
    :sign_in_count,
    :current_sign_in_at,
    :last_sign_in_at,
    :current_sign_in_ip,
    :last_sign_in_ip,
    :confirmation_token,
    :confirmed_at,
    :confirmation_sent_at,
    :created_at,
    :updated_at,
    :has_changed_password
  ]                
  
  before_validation do |user|
    if (user.email_changed? && !user.email.ascii_only?)
      user.email.gsub!(/[^\p{ASCII}]/u,'')
    end
    user.tracking_code ||= User.random_tracking_code
    true
  end
  
  before_save do |user|
    if (!user.new_record? && user.password)
      user.has_changed_password = true
    end
    
    if (!user.send_welcome_flag && (user.new_record? || user.has_changed_password_changed?) && user.has_changed_password)
      user.send_welcome_flag = true
    end
    true
  end
  
  after_create do |user|
    UserActivity.create(
      :user => user,
      :member => nil,
      :name => user.name,
      :email => user.email,
      :action => "Sign up",
      :description => "#{user} signed up"
    )
    true
  end
  
  after_commit do |user|
    if (user.send_welcome_flag)
      Resque.enqueue(Jobs::Notify::Welcome, user.id)
      user.send_welcome_flag = false
    end
    true
  end
  
  def export
    hash = super
    hash["attributes"].delete("encrypted_password")
    hash["attributes"]["has_changed_password"] = false
    return hash
  end

  def User.import(hash)
    unless (u = User.find_by_email(hash["attributes"]["email"].downcase))
      pw = "#{Time.now.to_i}#{rand(1000)}"
      hash["attributes"]["password"] = pw
      hash["attributes"]["password_confirmation"] = pw
      u = super(hash)
    end
    return u
  end

  def to_s
    self.name
  end
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      h = {
        :type => self.class.name.underscore,
        :id => self.id,
        :email => self.email,
        :home_page => self.setting.home_page,
        :last_sign_in_at => self.last_sign_in_at,
        :name => self.name,
        :photo_url => image_path("v2/default-avatar.jpg"),
        :time_zone => self.setting.time_zone,
        :time_zone_offset => ActiveSupport::TimeZone.new(self.setting.time_zone).now.utc_offset
      }
      h[:admin] = true if self.admin
      h
    end
  end

  def all_members_from_all_projects
    Member.where(:project_id =>
                     Project.joins(:members => :user).
                         where(:members => {:user_id => id, :activated => true})).
        where(:activated => true).
        where("members.user_id <> ?", id).
        order("created_at DESC").
        limit(5)
  end

  def live_projects
    self.projects.order("lower(projects.name)").includes(:members).where(:members => {:activated => true})
  end

  def most_recent_posts(page=1)
    BlogPost.published.
        includes(:member => :user).includes(:member => :project).
        where(:project_id => Member.select(:project_id).
        where(:members => {:user_id => self.id}, :activated => true).map(&:project_id)).
        order("blog_posts.published_at DESC").page(page)
  end

  def is_admin_on_any_project?
    self.live_projects.where(:members => {:level => "Owner"}).find(:first).present?
  end

  def is_admin?(project)
    return false if project.nil?
    #TODO: can only be a member on a project once
    # TODO: is this a better implementation
    #count = Project.where(:id => project.id).
    #    joins(:members).
    #    where(:members => {:user_id => self.id, :join_code => nil, :activated => true, :level => "Owner"}).
    #    count
    #count > 0

    members_with_authority = project.members.select do |m|
      m.level == 'Owner' && m.joined_and_active?
    end
    members_with_authority.map(&:user).include? self
  end

  def is_admin_or_normal_on_any_non_LLL_project?
    arel = Member.arel_table
    admin_or_normal = arel[:level].eq("Owner").or(arel[:level].eq("Normal"))
    self.live_projects.where(admin_or_normal).find(:first).present?
  end

  def membership_on(project)
    project.members.active.where(:user_id => self.id).first
  end

  def joined_and_active_on?(project)
    member = membership_on(project)
    member && member.joined_and_active?
  end

  def projects_user_can_edit_blogposts # TODO: should this take an all_projects parameter to use when it calls Ability.new
    projects.map do |p|
      p.id if Ability.new(self).can?(:manage, p.blog_posts.build)
    end
  end

  def last_activity_12hours_out
    twelve_ago = Time.now.utc - 12.hours
    activity = user_activities.unscoped.where("created_at < ?", twelve_ago).order("created_at DESC").limit(1)
    activity.present? ? activity.first.created_at : Time.now.utc - 12.hours
  end

  def new_posts_and_comments(page=1)
    last_activity = last_activity_12hours_out
    BlogPost.published.
        includes(:member => :user).includes(:member => :project).includes(:comments).
        where(:project_id => Member.select(:project_id).
        where(:members => {:user_id => self.id}, :activated => true).map(&:project_id)).
        where("blog_posts.published_at > ? OR comments.created_at > ?", last_activity, last_activity).
        order("blog_posts.published_at DESC").page(page)
  end

  def comments_to_highlight(posts)
    last_activity = last_activity_12hours_out
    comments = Comment.where(:blog_post_id => posts.map(&:id))
    comments.map { |c| c.id if c.created_at > last_activity }
  end

  def posts_to_highlight(posts)
    last_active = last_activity_12hours_out
    posts.map { |p| p.id if p.created_at > last_active }
  end

  def self.new_inactive
    now = Time.now.utc
    active_user_ids = BlogPost.all.map { |b| b.member.user_id }.uniq
    active_user_ids += Comment.all.map { |c| c.member.user_id }.uniq
    User.where("id NOT IN (?)", active_user_ids).
        where(:confirmed_at => (now - 3.days .. now - 2.days))
  end
 
  def create_associated_setting
    self.create_setting
  end
  private :create_associated_setting

  def cohort
    oldest = Rails.cache.fetch("User.oldest") do
      User.order(:created_at).first.created_at.to_date
    end
    return (self.created_at.to_date - oldest.to_date).to_i / 7 + 1
  end
  
  def User.random_tracking_code
    rand(2 ** 50).to_i.to_s    
  end
    
end

