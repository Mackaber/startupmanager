#encoding: utf-8
# TODO: rename this ProjectMailer
class BlogPostMailer < ActionMailer::Base

  def mail_contents_of_blog_post(blog_post, bcc)
    @blog_post = blog_post
    mail(:bcc => bcc,
         :subject => "(#{blog_post.member.user.name}) #{blog_post.subject}",
         :from => "#{blog_post.project.name} Update <#{ENV['EMAIL_NOTIFICIATIONS']}>"
    )
  end

  def mail_contents_of_comment(comment, object, bcc)
    @comment = comment
    @object = object
    mail(:bcc => bcc,
         :subject => "(#{comment.member.user.name}) #{@object}",
         :from => "#{comment.project} Comment <#{ENV['EMAIL_NOTIFICIATIONS']}>"         
    )
  end

  def daily_summary(user, projects, start_at, end_at)
    @projects = projects.sort_by{|x| x[:project].name.downcase}
    @start_at = start_at
    @end_at = end_at
    @user = user
    mail(:to => user.email,
         :subject => digest_subject(user, projects, "Daily Summary"))
  end

  def weekly_summary(user, projects, start_at, end_at)
    @projects = projects.sort_by{|x| x[:project].name.downcase}
    @start_at = start_at
    @end_at = end_at
    @user = user
    mail(:to => user.email,
         :subject => digest_subject(user, projects, "Weekly Scorecard"))
  end
  
  def member_deactivated(member, user_id)
    @member = member
    mail(
      :to => member.project.members.active.admin.select{|x| x.user_id != user_id}.collect{|x| x.user.email},
      :subject => "#{member.user} left project #{member.project}"
    )
  end

  def comment_updated(comment, new_record, member)
    @comment = comment
    @new_record = new_record
    @can_comment = Ability.new(member.user).can?(:create, comment.subject.comments.build)
    attrs = {
      :to => member.user.email,
      :subject => "#{new_record ? 'New' : 'Updated'} Comment (#{comment.subject.project}): #{comment.subject}"      
    }
    if @can_comment
      s = comment.blog_post_id ? "l3b#{comment.blog_post_id}@" : "l3h#{comment.hypothesis_id}@"
      s << (Rails.env == "production" ? ENV["HOSTNAME"] : Rails.application.config.action_mailer.default_url_options[:host])
      attrs[:reply_to] = s
    end
    mail(attrs)
  end
  
  def hypothesis_updated(hypothesis, new_record, member)
    @hypothesis = hypothesis
    @new_record = new_record
    @can_comment = Ability.new(member.user).can?(:create, hypothesis.comments.build)    
    status = "#{hypothesis.item_status || 'updated'}".capitalize
    attrs = {
      :to => member.user.email,
      :subject => "#{new_record ? 'New' : status} Hypothesis (#{hypothesis.project}): #{hypothesis}"
    }
    attrs[:reply_to] = "l3h#{hypothesis.id}@#{Rails.env == 'production' ? ENV["HOSTNAME"] : Rails.application.config.action_mailer.default_url_options[:host]}" if @can_comment
    mail(attrs)
  end

  def hypothesis_validated(hypothesis, member)
    @hypothesis = hypothesis
    @can_comment = Ability.new(member.user).can?(:create, hypothesis.comments.build)    
    attrs = {
      :to => member.user.email,
      :subject => "Hypothesis Validated (#{hypothesis.project}): #{hypothesis}"
    }
    attrs[:reply_to] = "l3h#{hypothesis.id}@#{Rails.env == 'production' ? ENV["HOSTNAME"] : Rails.application.config.action_mailer.default_url_options[:host]}" if @can_comment
    mail(attrs)
  end

  def interview_updated(interview, new_record, member)
    @blog_post = interview
    @new_record = new_record
    @can_comment = Ability.new(member.user).can?(:create, interview.comments.build)    
    attrs = {
      :to => member.user.email,
      :subject => "#{new_record ? 'New' : 'Updated'} Interview (#{interview.project}): #{interview}"
    }
    attrs[:reply_to] = "l3b#{interview.id}@#{Rails.env == 'production' ? ENV["HOSTNAME"] : Rails.application.config.action_mailer.default_url_options[:host]}" if @can_comment
    mail(attrs)
  end

  def task_assigned(task, assigned_by_user)
    @task = task
    @assigned_by_user = assigned_by_user
    member = task.assigned_to_member
    @can_comment = false #Ability.new(member.user).can?(:create, task.comments.build)    
    attrs = {
      :to => member.user.email,
      :subject => "Task '#{task}' assigned to you"
    }
    # attrs[:reply_to] = "l3t#{task.id}@#{Rails.env == 'production' ? ENV["HOSTNAME"] : Rails.application.config.action_mailer.default_url_options[:host]}" if @can_comment
    mail(attrs)
  end
  
  def update_updated(update, new_record, member)
    @blog_post = update
    @new_record = new_record
    @can_comment = Ability.new(member.user).can?(:create, update.comments.build)    
    attrs = {
      :to => member.user.email,
      :subject => "#{update.urgent ? "URGENT " : ""}#{new_record ? 'New' : 'Updated'} Update (#{update.project}): #{update}"
    }
    attrs[:reply_to] = "l3b#{update.id}@#{Rails.env == 'production' ? ENV["HOSTNAME"] : Rails.application.config.action_mailer.default_url_options[:host]}" if @can_comment
    mail(attrs)
  end
  
  private

  #TODO move this to lib/blog_digest or somewhere not testable from here
  def digest_subject(user, projects, label)
    count = projects.count
    subject = "#{label}"
    subject += " for #{projects.first[:project].name}" unless count.zero?
    case
      when count == 2
        subject += " and 1 other project"
      when count > 2
        subject += " and #{count - 1} other projects"
    end
    subject
  end
end
