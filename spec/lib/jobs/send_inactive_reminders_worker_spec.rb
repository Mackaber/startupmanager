require "spec_helper"

describe Jobs::SendInactiveReminders do
  before do
    #make some active users
    (1..4).each { |i| m = Factory(:owner)
    m.user.update_attribute(:confirmed_at, i.days.ago)
    if i % 2 == 0
      Factory(:blog_post, :member => m)
    else
      Factory(:comment, :member => m)
    end
    }
  end

  describe "without inactive users" do
    it "does not send mail" do
      UserMailer.should_not_receive(:new_user_inactive)
      Jobs::SendInactiveReminders.perform
    end
  end

  describe "with inactive users" do
    before do
      (1..4).each { |i| m = Factory(:owner)
      m.user.update_attribute(:confirmed_at, i.days.ago)
      }
      @message = double
    end

    it "sends email to inactive users" do
      @message.should_receive(:deliver).once
      UserMailer.should_receive(:new_user_inactive).once.and_return(@message)
      Jobs::SendInactiveReminders.perform
    end

  end
end

