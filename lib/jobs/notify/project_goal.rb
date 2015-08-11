class Jobs::Notify::ProjectGoal < Jobs::Job
  
  def self.run()
    now = Time.now.beginning_of_day
    Project.where(["updated_at BETWEEN ? AND ?", now-4.days, now-3.days]).find_each do |project|   
      template = nil
      if (project.goal_invite_completed)
        # done!
        next
      elsif (project.goal_interview_completed)
        template = :goal_invite
      elsif (project.goal_validate_hypothesis_completed)
        template = :goal_interview
      elsif (project.goal_test_hypothesis_completed)
        template = :goal_validate
      elsif (project.goal_create_hypothesis_completed)
        template = :goal_test
      elsif (project.goal_canvas_completed)
        template = :goal_hypothesis
      else
        template = :goal_canvas
      end
      project.members.active.where(:role_name => "Contributor", :notify_goals => true).find_each do |member|
        if (member.user.setting.send("project_#{template}_notified_at").nil?)
          ProjectMailer.send(template, member).deliver
          member.user.setting.update_attribute("project_#{template}_notified_at", Time.now)
        end
      end
    end
  end
  
end