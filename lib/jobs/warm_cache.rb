#encoding: utf-8
class Jobs::WarmCache < Jobs::Job
  def self.run
    User.find_each do |user|
      user.to_hash
    end
    Organization.find_each do |organization|
      organization.to_hash
      organization.organization_members.collect{|x| x.to_hash}
      organization.charges.collect{|x| x.to_hash}
    end
    Project.find_each do |project|
      project.to_hash
      blog_posts = project.blog_posts.published
      hypotheses = project.hypotheses
      both = (blog_posts + hypotheses)
      both.collect{|x| x.attachments}.flatten.collect{|x| x.to_hash}
      blog_posts.collect{|x| x.to_hash}
      both.collect{|x| x.comments}.flatten.collect{|x| x.to_hash}
      hypotheses.collect{|x| x.experiments}.flatten.collect{|x| x.to_hash}
      hypotheses.collect{|x| x.to_hash}
      project.members.collect{|x| x.to_hash}
      hypotheses.collect{|x| x.questions}.flatten.collect{|x| x.to_hash}
      hypotheses.collect{|x| x.tasks}.flatten.collect{|x| x.to_hash}
      project.members.collect{|x| x.user.to_hash}
    end
  end
end
