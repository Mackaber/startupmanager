#encoding: utf-8
class Jobs::DeleteProject < Jobs::Job
  
  def self.run(project_id, user_id)
    if (project = Project.find_by_id(project_id))
      Audit.as_user(User.find_by_id(user_id)) do
        project.members.find_each do |member|
          member.destroy
        end
        project.destroy
      end
    end
  end
  
end
