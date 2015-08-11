require "spec_helper"

describe Jobs::SendInactiveForSevenDays do
  before do
    #make some active users
    (1..6).each do |i|
      m = Factory(:owner)
      Factory(:user_activity, :member_id => m.id, :created_at => i.days.ago)
    end
  end

  describe "without inactive users" do
    it "does not send mail" do
      UserMailer.should_not_receive(:new_user_inactive)
      Jobs::SendInactiveForSevenDays.perform
    end
  end

  describe "with inactive users" do
    before do
      (1..4).each do |i|
        m = Factory(:owner)
        Factory(:user_activity, :member_id => m.id, :created_at => (4 + i).days.ago)
      end
      @message = double
    end

    it "sends email to inactive users" do
      @message.should_receive(:deliver).once
      UserMailer.should_receive(:new_user_inactive).once.and_return(@message)
      Jobs::SendInactiveForSevenDays.perform
    end

  end
end

