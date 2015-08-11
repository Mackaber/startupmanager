class Jobs::Notify::Summary < Jobs::Job
  
  def self.run
    end_at = Time.now
    start_at = end_at - 1.day
    
    time_zones = ActiveRecord::Base.connection.execute("SELECT DISTINCT(time_zone) FROM settings").entries.collect{|x| x["time_zone"]}
    time_zones = time_zones.select{|x| now = ActiveSupport::TimeZone.new(x).now; now.hour == 8}
    i = 0
    Setting.where(["time_zone IN (?)", time_zones]).find_each do |setting|
      begin
        daily_summary(setting.user, start_at, end_at)
      rescue Exception => exception
        report_error(exception)
      end
      if ((i += 1) % 10).zero?
        sleep 1
      end
    end

    start_at = end_at - 1.week

    time_zones = ActiveRecord::Base.connection.execute("SELECT DISTINCT(time_zone) FROM settings").entries.collect{|x| x["time_zone"]}
    time_zones = time_zones.select{|x| now = ActiveSupport::TimeZone.new(x).now; (now.wday == 0) && (now.hour == 20)}
    i += 1
    Setting.where(["time_zone IN (?)", time_zones]).find_each do |setting|
      begin
        weekly_summary(setting.user, start_at, end_at)
      rescue Exception => exception
        report_error(exception)
      end
      if ((i += 1) % 10).zero?
        sleep 1
      end
    end
  end
  
  def self.daily_summary(user, start_at, end_at)
    projects = user.members.active.where(:daily_summary => true).collect do |member|
      blog_posts = member.project.blog_posts.published.active_since(start_at, end_at).sort_by{|x| x.published_at}.reverse
      interviews = blog_posts.select{|x| x.is_a?(BlogPost) && x.post_type == "interview"}
      updates = blog_posts.select{|x| x.is_a?(BlogPost) && x.post_type != "interview"}
      
      started_hypotheses = member.project.hypotheses.where(:item_status_id => ItemStatus.cached_find_by_status("started").id).sort_by{|x| x.position || 0}
      
      completed_hypotheses = member.project.hypotheses.where(["item_status_id IN (?) AND completed_at BETWEEN ? AND ?", [ItemStatus.cached_find_by_status("valid").id, ItemStatus.cached_find_by_status("invalid").id, ItemStatus.cached_find_by_status("unknown").id], end_at-7.days+1, end_at]).sort_by{|x| x.completed_at}.reverse.slice(0,5)
      
      last_activity_at = (member.project.last_activity_at || member.project.created_at)
        
      {
        :project => member.project,
        :blog_posts => blog_posts,
        :interviews => interviews,
        :updates => updates,
        :started_hypotheses => started_hypotheses,
        :completed_hypotheses => completed_hypotheses,
        :last_activity_at => (blog_posts.empty? && started_hypotheses.empty? && completed_hypotheses.empty?) ? last_activity_at : nil,
        :recent => (last_activity_at >= start_at)
      }
    end
    some_active = projects.find{|p| p[:recent]}
    if (!projects.empty? && some_active)
      BlogPostMailer.daily_summary(user, projects, start_at, end_at).deliver
    end
  end
  
  def self.weekly_summary(user, start_at, end_at)
    projects = user.members.active.where(:weekly_summary => true).collect do |member|
      recent = member.project.blog_posts.published.active_since(start_at, end_at) + member.project.hypotheses.where(["created_at BETWEEN ? AND ? OR completed_at BETWEEN ? AND ?", start_at, end_at, start_at, end_at]).sort_by{|x| x.attributes["completed_at"] || x.attributes["published_at"] || x.attributes["created_at"]}.reverse.slice(0,5)
         
      {
        :project => member.project,
        :recent => recent
      }
    end
    unless projects.empty?
      BlogPostMailer.weekly_summary(user, projects, start_at, end_at).deliver
    end
  end
    
end
