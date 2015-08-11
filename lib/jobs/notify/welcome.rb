class Jobs::Notify::Welcome < Jobs::Job
  
  def self.run(user_id)
    if (user = User.find_by_id(user_id))
      UserMailer.welcome(user).deliver
    end
  end

end