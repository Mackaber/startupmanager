class Jobs::Notify::MemberActivated < Jobs::Job
    
  def self.run(inviter_user_id, member_id, new_user, new_member) 
    if ((user = User.find_by_id(inviter_user_id)) && (member = Member.find_by_id(member_id)))
      if (new_user)
        UserMailer.add_to_project_new_user(member, user).deliver
      elsif (new_member)
        UserMailer.add_to_project(member, user).deliver
      else
        UserMailer.notify_reactivated(member, user).deliver      
      end
    end
  end
  
end