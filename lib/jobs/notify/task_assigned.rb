class Jobs::Notify::TaskAssigned < Jobs::Job
  
  def self.run(task_id, assigned_by_user_id)
    if ((task = ProjectTask.find_by_id(task_id)) && task.assigned_to_member)
      BlogPostMailer.task_assigned(task, User.find_by_id(assigned_by_user_id)).deliver
    end
  end

end