class Jobs::Notify::MemberDeactivated < Jobs::Job
  
  def self.run(member_id, user_id)
    if ((member = Member.find_by_id(member_id)) && !member.activated)
      BlogPostMailer.member_deactivated(member, user_id).deliver
    end
  end

end