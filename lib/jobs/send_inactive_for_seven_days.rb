#encoding: utf-8
class Jobs::SendInactiveForSevenDays < Jobs::Job
  def self.run
    #UserActivity.unscoped.select("user_id, max(created_at)").group(:user_id).having("max(created_at) < date '?' ", 7.days.ago )
    UserActivity.find_by_sql("select user_id, max(created_at) from user_activities group by user_id having max(created_at) < date '#{7.days.ago}';").each do |row|
      user = User.find(row.user_id)
      UserMailer.new_user_inactive(user).deliver
    end
  end
end