require "spec_helper"

describe Jobs::SendUnjoinedReminders do
  pending "no confirmation" do

    describe "confirmation reminders" do
      before do
        @now = Time.now.utc
        @owner = Factory(:owner)
        @project = @owner.project
        (1..4).each { |i| m = Factory(:member_who_has_joined_project, :created_at => @now - i.days,
                                      :project => @project)
        m.user.update_attribute(:name, "#joined #{i} days ago")
        }
      end

      describe "without unjoined users" do
        it "does not send mail" do
          UserMailer.should_not_receive(:remind_unjoined)
          Jobs::SendUnjoinedReminders.perform
        end
      end

      describe "with unjoined users" do
        before do
          @unjoined = []
          (1..6).each { |i| m = Factory(:member, :created_at => @now - i.days, :project => @project)
          m.user.update_attribute(:name, "unjoined for #{i} days")
          @unjoined << m
          }
          @message = double
          @posts = (1..2).map { Factory(:blog_post, :project => @project) }
        end

        it "sends email to users unjoined for 2 days and 5 days" do
          @message.should_receive(:deliver).twice
          UserMailer.should_receive(:remind_unjoined).twice.and_return(@message)
          Jobs::SendUnjoinedReminders.perform
        end

        it "sets the parameters on remind_unjoined call" do
          pending "this never sees the member param don't know why"
          @message.should_receive(:deliver)
          member = @unjoined[3]
          authors = @posts.map { |p| p.member.user.name }.sort.join(', ')
          UserMailer.should_receive(:remind_unjoined).with(member, @owner.user.name, 2, authors)
          Jobs::SendUnjoinedReminders.perform
        end

      end
    end

  end
end