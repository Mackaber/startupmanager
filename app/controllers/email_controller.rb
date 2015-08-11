class EmailController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  skip_before_filter :require_login_and_password_change
  skip_authorization_check
  
  def index
    content = params[:email].read
    message = Mail.read_from_string(content)
      
    ((message.to || []) + (message.cc || [])).each do |addr|
      lhs, rhs = addr.split("@")
      next unless (rhs =~ /leanlaunchlab\.com$/)
      
      if (
        message.header["Precedence"] == "bulk" ||
        message.header["X-Autoreply"] == "yes" ||
        message.subject =~ /(auto(matic)? ?(reply|response)|out of (the )?office)/i
      )
        Rails.logger.debug("Ignoring auto-reply: #{message.header}")
        next
      end
      
      if (lhs =~ /^l3b([0-9]+)$/)
        blog_post = BlogPost.find_by_id($1)
        next if blog_post.nil?
        process_reply(message, blog_post)
      elsif (lhs =~ /^l3c([0-9]+)$/)      # FIXME: deprecated
        comment = Comment.find_by_id($1)
        next if comment.nil?
        process_reply(message, comment.subject)
      elsif (lhs =~ /^l3e([0-9]+)$/)      # FIXME: deprecated
        experiment = Experiment.find_by_id($1)
        next if experiment.nil?
        process_reply(message, experiment)
      elsif (lhs =~ /^l3h([0-9]+)$/)
        hypothesis = Hypothesis.find_by_id($1)
        next if hypothesis.nil?
        process_reply(message, hypothesis)
      elsif (lhs =~ /^l3t([0-9]+)$/)      # FIXME: deprecated
        task = ProjectTask.find_by_id($1)
        next if task.nil?
        process_reply(message, task)
      end       
    end
    
    render(:nothing => true)
  end
  
  def process_reply(message, object)
    user = User.find_by_email(message.envelope_from.downcase)
    if user.nil?
      Rails.logger.debug("Ignoring unknown user #{message.envelope_from}: #{message.headers}")
      return
    end
    
    ability = Ability.new(user)
    unless ability.can?(:create, object.comments.build)
      Rails.logger.debug("Ignoring read-only member: #{user.email}")
      return
    end
      
    if (message.multipart?)
      part = message.parts.select{|p| p.content_type =~ /^text\/plain/}.first
      text = part ? part.body.decoded : nil
    else
      text = message.body.decoded
    end
    
    if (text.blank?)
      Rails.logger.debug("Unable to find text part: #{message.parts.collect{|p| p.content_type}.join(', ')}")
      return
    end
    
    attribution = Regexp.new("On.*20[0-9]{2}.*wrote:", Regexp::IGNORECASE)
    attribution_first = Regexp.new("^On .* 20[0-9]{2}", Regexp::IGNORECASE)
    attribution_last = Regexp.new(" wrote:", Regexp::IGNORECASE)
    regexp = Regexp.new(Comment::REPLY_DELIMITER)
    s = []
    lines = text.lines.to_a
    lines.each_with_index do |line,i|
      break if attribution.match(line) || regexp.match(line)
      # yahoo
      break if line =~ /^\_{5,}$/
      #hotmail
      if i > 0 && line =~ /^From: / && s[i-1] =~ /^Date: /
        s.pop
        break
      end
      # aol
      break if line =~ /^\-+Original Message/
      if (i > 0 && attribution_last.match(line) && attribution_first.match(s[i-1]))
        s.pop
        break
      end
      s << line
    end
    text = s.join("\n").strip    
    return if text.blank?
    
    Audit.as_user(user) do
      object.comments.create!(:member => user.members.where(:project_id => object.project_id).first, :body => text)
    end
  end
  protected :process_reply
    
end