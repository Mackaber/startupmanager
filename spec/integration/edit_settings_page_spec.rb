require "spec_helper"


describe "Edit settings" do

  before do
    @owner = Factory(:owner)
    @user = @owner.user
    @project1 = @owner.project
    login_with_email_and_password(@user)
    visit edit_settings_path
  end

  after do
    visit destroy_user_session_path #sign out
  end

  describe "email digest" do
    before do
      page.has_checked_field?('setting_post_email').should be_true
      page.has_checked_field?('setting_feedback_email').should be_true
    end

    it 'unchecks "New Blog Post" and "New Feedback" when "Daily Digest" is checked' do
      check("setting_digest_email")
      page.has_checked_field?('setting_digest_email').should be_true
      page.has_checked_field?('setting_post_email').should be_false
      page.has_checked_field?('setting_feedback_email').should be_false
    end

    describe 'unchecks "Daily Digest"' do
      it 'when "New Blog Post" is checked' do
        uncheck('setting_post_email')
        page.has_checked_field?('setting_digest_email').should be_false
        page.has_checked_field?('setting_post_email').should be_false
        page.has_checked_field?('setting_feedback_email').should be_true
      end

      it 'when "New Feedback" is checked' do
        uncheck("setting_feedback_email")
        page.has_checked_field?('setting_digest_email').should be_false
        page.has_checked_field?('setting_post_email').should be_true
        page.has_checked_field?('setting_feedback_email').should be_false
      end
    end
  end

end
