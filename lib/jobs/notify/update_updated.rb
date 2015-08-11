class Jobs::Notify::UpdateUpdated < Jobs::Job
  
  def self.run(update_id, new_record)
    if (update = BlogPost.find_by_id(update_id))
      update.project.members.active.where(["id <> ? AND notify_updates = 't'", update.member_id]).find_each do |member|
        BlogPostMailer.update_updated(update, new_record, member).deliver
      end
    end
  end
  
end