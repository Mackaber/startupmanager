class Jobs::Notify::HypothesisUpdated < Jobs::Job
  
  def self.run(hypothesis_id, new_record)
    if (hypothesis = Hypothesis.find_by_id(hypothesis_id))
      conditions = ["notify_hypotheses = 't'"]
      audit = hypothesis.audits.last
      if (audit.user_id)
        conditions[0] << " AND user_id <> ?"
        conditions << audit.user_id
      end
      hypothesis.project.members.active.where(conditions).find_each do |member|
        BlogPostMailer.hypothesis_updated(hypothesis, new_record, member).deliver
      end
    end
  end
  
end