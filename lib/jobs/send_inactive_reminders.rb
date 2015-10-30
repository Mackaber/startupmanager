#encoding: utf-8
class Jobs::SendInactiveReminders < Jobs::Job
  def self.run
    User.new_inactive.each {|u| UserMailer.new_user_inactive(u).deliver}
  end
end