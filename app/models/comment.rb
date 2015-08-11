class Comment < ActiveRecord::Base

  belongs_to :blog_post, :touch => true  
  belongs_to :hypothesis, :touch => true
  belongs_to :member
  has_one :project, :through => :member
  
  REPLY_DELIMITER = "Reply ABOVE THIS LINE to add a comment to this thread"

  validates_presence_of :member
  validates_presence_of :body
  
  validate do |comment|
    comment.errors[:base] << ("must be associated with something") unless (comment.blog_post || comment.hypothesis)
    true
  end

  # after_create :mail_project_members

  attr_accessor :prompt
  attr_accessor :notify_flag

  include ImportExport  
  include Sanitized
  
  acts_as_audited :associated_with => :project
  
  before_create do |comment|
    if (comment.body_changed?)    
      comment.notify_flag = (comment.new_record? ? :new : :updated)
    end
  end
  
  after_commit do |comment|
    if (comment.notify_flag)
      Resque.enqueue(Jobs::Notify::CommentUpdated, comment.id, comment.notify_flag == :new)
    end
    true
  end
  
  def export
    hash = super
    hash["relationships"] = {
      "blog_post_id" => self.blog_post_id, 
      "hypothesis_id" => self.hypothesis_id, 
      "member_id" => self.member_id
    }
    return hash
  end
  
  # def Comment.import(hash, blog_post, member)
  #   m = super(hash)
  #   m.blog_post = blog_post
  #   m.member = member
  #   return m
  # end
  
  def to_s
    "#{self.body}"[0..3]
  end
  
  def mail_to
    members = self.member.project.members.select { |m| m.joined_and_active? && m.user.setting.feedback_email &&
        m.level != "Viewer" } - [self.member]
    members.collect { |m| m.user.email }.join(', ')
  end
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :blog_post_id => self.blog_post_id,
        :hypothesis_id => self.hypothesis_id,
        :body => self.body,
        :created_at => self.created_at,
        :member_id => self.member_id
      }
    end
  end
  
  def subject
    (self.blog_post || self.hypothesis)
  end
  
  def subject_type
    case self.subject.class.name
    when "BlogPost"
      self.subject.post_type == "interview" ? "interview" : "update"
    when "Hypothesis"
      "hypothesis"
    end
  end
  
  def project
    @project = self.subject.project
  end
  
  private

  def mail_project_members
    to = mail_to
    if to.length > 0
      BlogPostMailer.mail_contents_of_comment(self, (self.blog_post || self.hypothesis), to).deliver
    end
  end
end
