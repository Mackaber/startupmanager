class Jobs::Notify::CommentUpdated < Jobs::Job
  
  def self.run(comment_id, new_record)
    if (comment = Comment.find_by_id(comment_id))
      subject = comment.subject
      attr = "notify_" + comment.subject_type.pluralize
      subject.project.members.active.where(["id <> ? AND #{attr} = 't'", comment.member_id]).find_each do |member|
        BlogPostMailer.comment_updated(comment, new_record, member).deliver
      end
    end
  end
  
end