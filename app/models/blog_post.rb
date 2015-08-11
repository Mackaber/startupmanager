class BlogPost < ActiveRecord::Base
  
  has_many :attachments, :as => :item, :dependent => :destroy
  has_many :boxes
  has_many :comments, :order => "comments.created_at ASC", :dependent => :destroy
  belongs_to :member
  has_many :member_blog_post_views, :dependent => :destroy
  belongs_to :project, :touch => true
  has_many :pictures, :class_name => "Ckeditor::Picture", :foreign_key => "assetable_id", :conditions => "assetable_type = 'BlogPost'", :dependent => :destroy

  acts_as_audited :associated_with => :project
  
  attr_accessor :notify_flag
  
  scope(:draft, where(:published_at => nil))
  
  scope(:published, where("published_at IS NOT NULL"))
  
  scope(:interviews, where(:post_type => "interview"))
  
  scope(:updates, where("post_type IS NULL OR post_type <> 'interview'"))  
  
  # created/updated/commented/attached
  scope(
    :active_since, 
    lambda do |start_at, end_at|
      where(["updated_at BETWEEN ? AND ?", start_at, end_at])
    end
  )
      
  validates_presence_of :member, :subject
  
  validate do |blog_post|
    blog_post.errors[:base] << ("must be associated with something") unless (blog_post.project || blog_post.task || blog_post.hypothesis || blog_post.experiment)
    true
  end
  
  before_create do |blog_post|
    if (blog_post.subject_changed? || blog_post.body_changed? || (blog_post.post_type.nil? && (blog_post.the_ask_changed? || blog_post.urgent_changed?)) || (blog_post.post_type == "interview" && (blog_post.text1_changed? || blog_post.text2_changed? || blog_post.date_changed?)))
      blog_post.notify_flag = (blog_post.new_record? ? :new : :updated)
    end
    
    true
  end
  
  after_create do |blog_post|
    if (!blog_post.project.goal_interview_completed && blog_post.post_type == "interview")
      blog_post.project.goal_interview_completed = true
      blog_post.project.save!
    end
    true
  end
  
  before_save :truncate_subject
  
  before_save do |blog_post|
    blog_post.date ||= blog_post.published_at.in_time_zone("Pacific Time (US & Canada)").to_date if blog_post.published_at   
    true 
  end
  
  after_commit do |blog_post|
    if (blog_post.notify_flag)
      Resque.enqueue(blog_post.post_type == "interview" ? Jobs::Notify::InterviewUpdated : Jobs::Notify::UpdateUpdated, blog_post.id, blog_post.notify_flag == :new)
    end
    
    true
  end
  
  include ImportExport  
  include Sanitized
  
  def export
    hash = super
    hash["relationships"] = {
      "member_id" => self.member_id,
      "project_id" => self.project_id
    }
    return hash
  end    
  
  # def BlogPost.import(hash, member, project)
  #   bp = super(hash)    
  #   bp.member = member
  #   bp.project = project    
  #   return bp
  # end
  
  def to_s
    case (self.post_type)
    when "interview"
      "Interview with #{self.subject}#{!self.text1.blank? ? " (#{self.text1})" : nil}"
    else
      self.subject
    end    
  end
  
  def url
    if (self.post_type == "interview")
      "#{Rails.application.routes.url_helpers.interviews_project_url(self.project, Rails.application.config.action_mailer.default_url_options)}#blog_post/#{self.id}"
    else
      "#{Rails.application.routes.url_helpers.journal_project_url(self.project, Rails.application.config.action_mailer.default_url_options)}#blog_post/#{self.id}"
    end
  end

  def mail_to
    members = self.project.members.select { |m| m.joined_and_active? && m.user.setting.post_email && m.level != 'Viewer' } - [self.member]
    members.collect { |m| m.user.email }.join(', ')
  end

  def unread_comments(member)
    result_hash = {}
    return {:total_count => 0} if member.level == "Viewer"

    member_view = MemberBlogPostView.where(:blog_post_id => self.id, :member_id => member.id).first
    if member_view
      result = Comment.where("comments.blog_post_id = ? AND comments.created_at >= ? AND comments.member_id != ?", self.id, member_view.updated_at, member.id).select("users.name as name, count(comments.id) as count").joins(:member => :user).group("users.name")
    else
      result = Comment.where("comments.blog_post_id = ? AND comments.member_id != ?", self.id, member.id).select("users.name as name, count(comments.id) as count").joins(:member => :user).group("users.name")
    end

    result_hash[:count_for_users] = result.all
    result_hash[:total_count] = result.all.reduce(0) { |sum, x| sum + x.count.to_i }
    result_hash
  end

  def new_comment_authors
    recent_comments = comments.includes(:member => :user).where("comments.created_at > ? ", Time.now.utc - 24.hours)
    recent_comments.map { |c| c.member.user.name }.uniq.sort
  end

  def mail_project_members
    bcc = mail_to
    if bcc.length > 1
      BlogPostMailer.mail_contents_of_blog_post(self, bcc).deliver
    end
  end

  def publish(time = Time.now)
    self.published_at = time
  end
    
  def publish!(time = Time.now)
    self.publish(time)
    self.save! if self.changed?
    # self.mail_project_members
  end
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :urgent => self.urgent,
        :title => self.subject,
        :description => self.body,
        :the_ask => self.the_ask,
        :published_at => self.published_at,
        :date => self.date,
        :post_type => self.post_type,
        :text1 => self.text1,
        :text2 => self.text2,
        :member_id => self.member_id,
        :project_id => self.project_id
      }
    end
  end

  def truncate_subject
    self.subject = self.subject[0, 250] if self.subject
    true
  end
  private :truncate_subject
  
  def status_summary(start_at, end_at)
    changes = self.audits.where(["audits.created_at BETWEEN ? AND ?", start_at, end_at])
    if (changes.select{|x| x.action == "create"}.first)
      return "New"
    else
      return "Updated"
    end
  end

end
