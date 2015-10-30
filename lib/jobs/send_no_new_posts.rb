#encoding: utf-8
class Jobs::SendNoNewPosts < Jobs::Job
  def self.run
    Project.select { |p| p.blog_posts.published.select { |b| b.published_at > 7.days.ago }.empty? }.each do |project|
      project.members.where("is_owner = 't' OR role_name = 'Contributor' ").each do |member|
        UserMailer.no_new_posts(member).deliver
      end
    end
  end
end