require "spec_helper"

describe Jobs::SendNoNewPosts do
  before do
    puts "start project count = #{Project.count}"
    #make some active projects
    (1..3).each do |i|
      m = Factory(:owner)
      Factory(:blog_post, :member => m, :published_at => i.days.ago)
    end
    puts "should be 3 project count = #{Project.count}"
  end

  describe "without inactive projects" do
    it "does not send mail" do
      UserMailer.should_not_receive(:no_new_posts)
      Jobs::SendNoNewPosts.perform
    end
  end

  describe "with inactive projects" do
    before do
      puts "second before project count = #{Project.count}"
      m = Factory(:owner)
      Factory(:blog_post, :member => m, :published_at => 8.days.ago)
      @message = double
      puts "after second before project count = #{Project.count}"
    end

    it "sends email to inactive users" do
      puts "start project count = #{Project.count}"
      @message.should_receive(:deliver).once
      UserMailer.should_receive(:no_new_posts).once.and_return(@message)
      Jobs::SendNoNewPosts.perform
    end

  end
end

