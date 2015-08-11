require "spec_helper"

describe UserMailer do
  it "sends an email to an existing user who has been added to a project" do
    owner = Factory(:owner)
    member = Factory(:member, :project => owner.project, :join_code => '1232456789')
    email = UserMailer.confirm_add_to_project(member, owner.user)
    email.should deliver_to(member.user.email)
  end
  
  it "sends an email when re-activating a de-activated member" do
    owner = Factory(:owner)
    member = Factory(:member, :project => owner.project)
    email = UserMailer.notify_reactivated(member, owner.user)
    email.should deliver_to(member.user.email)
  end

  pending "no confirmation" do
    it "sends an email reminder to unjoined user" do
      owner = Factory(:owner)
      unjoined_member = Factory(:member, :project => owner.project)
      update_count = 3
      update_authors = "Huey, Dewey, Louie"
      email = UserMailer.remind_unjoined(unjoined_member, owner.user, update_count, update_authors)
      email.should deliver_to(unjoined_member.user.email)
    end
  end
  
  it "sends an welcome email " do
    user = Factory(:confirmed_user)
    email = UserMailer.welcome(user)
    email.should deliver_to(user.email)
  end

  it "sends an new_user_inactive email " do
    user = Factory(:confirmed_user)
    Factory(:member_who_has_joined_project, :project => Factory(:project))
    email = UserMailer.new_user_inactive(user)
    email.should deliver_to(user.email)
  end

  it "sends no_new_post email" do
    member = Factory(:owner)
    email = UserMailer.no_new_posts(member)
    email.should deliver_to(member.user.email)
  end

end
