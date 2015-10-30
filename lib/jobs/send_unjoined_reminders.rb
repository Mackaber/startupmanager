#encoding: utf-8
class Jobs::SendUnjoinedReminders < Jobs::Job
  def self.run
    members_unjoined = Member.unjoined_for(2)
    members_unjoined += Member.unjoined_for(5)
    members_unjoined.each do |member|
      owner_name = member.project.members.where(:is_owner => true).first.user.name
      updates = member.project.posts_since(member.created_at)
      update_count = updates.count
      update_authors = updates.map {|p| p.member.user.name}.uniq.sort.join(', ')
      UserMailer.remind_unjoined(member, owner_name, update_count, update_authors).deliver
    end
  end
end