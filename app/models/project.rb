class Project < ActiveRecord::Base
  has_many :attachments, :through => :members
  has_many :blog_posts, :order => "blog_posts.created_at DESC", :dependent => :destroy
  has_many :canvas_items, :dependent => :destroy
  belongs_to :cc_user, :class_name => "User"
  has_many :comments, :through => :members
  has_many :experiments
  has_many :hypotheses, :dependent => :destroy
  has_many :members, :dependent => :destroy
  belongs_to :organization, :touch => true
  has_many :questions
  has_many :tasks, :class_name => "ProjectTask", :dependent => :destroy  
  has_many :users, :through => :members

  validates_presence_of :organization
  validates_presence_of :name
  # validates_associated :members
  validates_length_of :pitch, :maximum => 140
  validates_format_of :url, :allow_blank => true, :with => /^((http|https|ftp)\:\/\/)?([a-zA-Z0-9\.\-]+(\:[a-zA-Z0-9\.&amp;%\$\-]+)*@)*((25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])|([a-zA-Z0-9\-]+\.)*[a-zA-Z0-9\-]+\.(com|edu|gov|int|mil|net|org|biz|arpa|info|name|pro|aero|coop|museum|[a-zA-Z]{2}))(\:[0-9]+)*(\/($|[a-zA-Z0-9\.\,\?\'\\\+&amp;%\$#\=~_\-]+))*$/
  validates_uniqueness_of :name, :scope => :organization_id

  accepts_nested_attributes_for :members
  accepts_nested_attributes_for :organization
  
  include ImportExport
  
  include Project::Canvas
  
  def export
    hash = super
    hash["relationships"] = {
      "organization_id" => self.organization_id
    }
    return hash
  end    
  
  # def Project.import(hash)
  #   bp = super(hash)    
  #   return bp
  # end
  
  acts_as_audited
  has_associated_audits
  
  validate do |project|
    if (project.new_record? && !project.organization.can_add_project?)
      project.errors.add(:base, "Organization #{project.organization} has the maximum number of projects and needs to be upgraded to a higher subscription level.")
    end
  end
    
  def to_s
    self.name
  end

  def owner
    self.members.where(:is_owner => true).find(:first)
  end
  
  def posts_since(datetime)
    blog_posts.where("published_at > ? ", datetime)
  end

  def blog_post_needing_feedback(member)
    self.blog_posts.where("member_id != ?", member.id) - BlogPost.joins(:comments).where(:project_id => self.id, :comments => {:member_id => member.id})
  end

  # return the newest items in the specified box < the specified date
  def canvas_items_for_utc_date(utc_datetime, box)
    ids = CanvasItem.select("max(id) as id").where("project_id = #{self.id} AND created_at < ?", utc_datetime).group("original_id").map(&:id)
    self.canvas_items.where(:id => ids, :box_id => box.id, :deleted => false)
  end

  def canvas_items_delta(utc_datetime, box)
    # current
    this_weeks_items = canvas_items_for_utc_date(utc_datetime, box).to_a
    this_weeks_ids = this_weeks_items.map(&:id)
    # original versions of current
    this_weeks_original_ids = this_weeks_items.map(&:original_id)
    # last week's current
    previous_weeks_items = canvas_items_for_utc_date(utc_datetime.end_of_week - 1.week, box).to_a
    # last week's current which changed this week
    delta_items = previous_weeks_items.map do |item|
      if this_weeks_original_ids.include? item.original_id
        if this_weeks_ids.include? item.id
          #its an unchanged item
          this_weeks_items.delete_if { |i| i.original_id == item.original_id }
          mark_item(item, false, false, false)
        else
          #its an edited item
          new_version = this_weeks_items.find { |i| i.original_id == item.original_id }
          this_weeks_items.delete_if { |i| i.original_id == item.original_id }
          unless new_version.text == item.text && new_version.item_status == item.item_status
            [mark_item(item, true, false, true), mark_item(new_version, false, true, true)]
          else
            #edit was made and then undone
            mark_item(new_version, false, false, false)
          end
        end
      else
        #its a deleted item
        mark_item(item, true, false, false)
      end
    end

    delta_items.flatten!

    delta_items += this_weeks_items.map do |item|
      # a completely new item
      mark_item(item, false, true, false)
    end

    delta_items
  end

  def members_for_level(level)
    case level
      when 'Viewer'
        return []
      when 'Normal'
        return members.where(:activated => true).includes(:user).order("lower(users.name)")
      when 'Owner'
        return members.where(:activated => true).includes(:user).order("lower(users.name)")
      else
        raise("invalid level '#{level}' passed to Project#members_for_level")
    end
  end
  
  def last_activity_at
    blog_post = self.blog_posts.order("updated_at DESC").limit(1).first    
    hypothesis = self.hypotheses.where("completed_at IS NOT NULL").order("completed_at DESC").limit(1).first    
    return [blog_post && blog_post.updated_at, hypothesis && hypothesis.completed_at].select{|x| x}.max
  end
  
  def color_code
    last = self.last_activity_at
    return (last.nil? || last < 2.weeks.ago) ? "red" : (last < 1.week.ago) ? "yellow" : "green"
  end   
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash") do
      last_canvas_item = self.canvas_items.order("created_at DESC").first
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :created_at => self.created_at,
        :updated_at => self.updated_at,
        :name => self.name,
        :url => self.url,
        :pitch => self.pitch,
        :canvas_startup_headers => self.canvas_startup_headers,
        :canvas_include_plan_default => self.canvas_include_plan_default,
        :canvas_highlight_new => self.canvas_highlight_new,

        :plan_url => Rails.application.routes.url_helpers.project_url(self, Rails.application.config.action_mailer.default_url_options),
        :canvas_url => Rails.application.routes.url_helpers.canvas_project_url(self, Rails.application.config.action_mailer.default_url_options),
        :tasks_url => Rails.application.routes.url_helpers.project_tasks_url(self, Rails.application.config.action_mailer.default_url_options),
        :interviews_url => Rails.application.routes.url_helpers.interviews_project_url(self, Rails.application.config.action_mailer.default_url_options),
        :journal_url => Rails.application.routes.url_helpers.journal_project_url(self, Rails.application.config.action_mailer.default_url_options),
        :members_url => Rails.application.routes.url_helpers.project_members_url(self, Rails.application.config.action_mailer.default_url_options),
        :members_import_url => Rails.application.routes.url_helpers.import_v1_members_url(Rails.application.config.action_mailer.default_url_options),
        :settings_url => Rails.application.routes.url_helpers.edit_project_url(self, Rails.application.config.action_mailer.default_url_options),

        :organization_id => self.organization_id,
        :color_code => self.color_code,
        :canvas_updated_at => last_canvas_item ? last_canvas_item.created_at : nil,
        
        :goal_canvas_completed => self.goal_canvas_completed,
        :goal_create_hypothesis_completed => self.goal_create_hypothesis_completed,
        :goal_test_hypothesis_completed => self.goal_test_hypothesis_completed,
        :goal_validate_hypothesis_completed => self.goal_validate_hypothesis_completed,
        :goal_interview_completed => self.goal_interview_completed,
        :goal_invite_completed => self.goal_invite_completed,
        
        :price => self.price,
        :payment_code => self.payment_code
      }
    end
  end
  
  def mark_item(item, delta_deleted, delta_added, delta_changed)
    item.delta_deleted = delta_deleted
    item.delta_added = delta_added
    item.delta_changed = delta_changed
    item
  end
  private :mark_item
  
  def top_poster(start_at, end_at)
    m = self.members.active.select(%Q{members.*, (\
(SELECT COUNT(*) FROM blog_posts JOIN audits ON blog_posts.id = audits.auditable_id AND audits.auditable_type = 'BlogPost' AND audits.action = 'create' WHERE blog_posts.project_id = members.project_id AND audits.user_id = members.user_id AND blog_posts.published_at BETWEEN '#{start_at.utc.to_s(:db)}' AND '#{end_at.utc.to_s(:db)}') + \
(SELECT COUNT(*) FROM hypotheses JOIN audits ON hypotheses.id = audits.auditable_id AND audits.auditable_type = 'Hypothesis' AND audits.action = 'create' WHERE hypotheses.project_id = members.project_id AND audits.user_id = members.user_id AND audits.created_at BETWEEN '#{start_at.utc.to_s(:db)}' AND '#{end_at.utc.to_s(:db)}') + \
(SELECT COUNT(*) FROM experiments JOIN audits ON experiments.id = audits.auditable_id AND audits.auditable_type = 'Experiment' AND audits.action = 'create' WHERE experiments.project_id = members.project_id AND audits.user_id = members.user_id AND audits.created_at BETWEEN '#{start_at.utc.to_s(:db)}' AND '#{end_at.utc.to_s(:db)}') + \
(SELECT COUNT(*) FROM tasks JOIN audits ON tasks.id = audits.auditable_id AND audits.auditable_type = 'ProjectTask' AND audits.action = 'create' WHERE tasks.project_id = members.project_id AND audits.user_id = members.user_id AND audits.created_at BETWEEN '#{start_at.utc.to_s(:db)}' AND '#{end_at.utc.to_s(:db)}') \
) as c}).order("c DESC, members.created_at ASC").first
    return m.c.to_i > 0 ? m : nil
  end
  
  def top_commenter(start_at, end_at)
    m = self.members.active.select(%Q{members.*, (\
(SELECT COUNT(*) FROM comments JOIN blog_posts ON comments.blog_post_id = blog_posts.id WHERE comments.member_id = members.id AND blog_posts.project_id = #{self.id} AND comments.created_at BETWEEN '#{start_at.utc.to_s(:db)}' AND '#{end_at.utc.to_s(:db)}') + \
(SELECT COUNT(*) FROM comments JOIN hypotheses ON comments.hypothesis_id = hypotheses.id WHERE comments.member_id = members.id AND hypotheses.project_id = #{self.id} AND comments.created_at BETWEEN '#{start_at.utc.to_s(:db)}' AND '#{end_at.utc.to_s(:db)}') \
) AS c}).order("c DESC, members.created_at ASC").first
    return m.c.to_i > 0 ? m : nil
  end
  
  def fix_canvas_items!
    
    raise unless self.canvas_items.where(:original_id => nil).count.zero?
    
    CanvasItem.transaction do
      self.lock!
    
      h = {}
      self.canvas_items.find_each do |canvas_item|
        h[canvas_item.original_id] = canvas_item
      end
    
      h.values.select{|x| x.inactive_at && !x.deleted}.each do |canvas_item|
        version = canvas_item.audits.last.version
        raise canvas_item.inspect if version < 2
        ci = canvas_item.revision(version-1)
        # puts "processing #{canvas_item.id} #{version} #{ci.attributes.inspect}"
        canvas_item.attributes = ci.attributes
        canvas_item.include_in_plan = true if canvas_item.hypothesis_id
        canvas_item.save!
      end
    end
    
  end

  # Split project off into own organization
  def split!
    Project.transaction do
      src = self.organization
      dest = Organization.create!(:name => self.name)
      self.update_attributes!(:organization => dest)
      
      self.members.each do |member|
        dest.organization_members.create!(:user => member.user, :level => member.level == "Owner" ? "Admin" : "Normal")
        unless (Member.joins("JOIN projects ON members.project_id = projects.id").where(["projects.organization_id = ?", src.id]).where(:user_id => member.user_id).count > 0)
          src.organization_members.where(:user_id => member.user_id).destroy_all
        end
      end
      
      src.touch
    end
  end
  
  LETTERS_AND_NUMBERS = ('A'..'Z').to_a + ("0".."9").to_a
  
  # yes, there's a race condition here. move along.
  def assign_payment_code!
    while (self.payment_code.nil? || Project.find_by_payment_code(self.payment_code))
      self.payment_code = (1..9).collect { LETTERS_AND_NUMBERS[rand 36] }.join
    end
    self.save!
  end
  
  def cleanup_canvas
    self.canvas_items.active.find_each do |canvas_item|
      if canvas_item.hypothesis_id
        self.hypotheses.where(:title => canvas_item.text).where(["id <> ?", canvas_item.hypothesis_id]).destroy_all
      end
    end
    self.hypotheses.group(:title).having("count(*) > 1").count.each do |title,count|
      first = self.hypotheses.where(:title => title).order(:created_at).first
      self.hypotheses.where(["title = ? AND id <> ?", title, first.id]).destroy_all
    end
  end
end