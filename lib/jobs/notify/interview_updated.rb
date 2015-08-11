class Jobs::Notify::InterviewUpdated < Jobs::Job
  
  def self.run(interview_id, new_record)
    if (interview = BlogPost.find_by_id(interview_id))
      interview.project.members.active.where(["id <> ? AND notify_interviews = 't'", interview.member_id]).find_each do |member|
        BlogPostMailer.interview_updated(interview, new_record, member).deliver
      end
    end
  end
  
end