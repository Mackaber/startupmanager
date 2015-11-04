require "spec_helper"

describe "Activity Stream page" do

  before do
    @user = Factory(:confirmed_user, :email => "jabier@StartupManager.co")

    5.times do |i|
      Factory(:user_activity, :created_at => Time.now + i.minutes)
    end

    2.times do |i|
      Factory(:user_activity, :created_at => Time.now + 24.hours + (i + 10).minutes)
    end

    visit user_session_path
    fill_in 'Email', :with => @user.email
    fill_in 'user_password', :with => @user.password
    click_link "Sign In"

    visit activity_stream_path
  end

  after do
    visit destroy_user_session_path #sign out
  end

  it 'should show a row for each UserActivity record' do
    UserActivity.all.each do |user_activity|
      page.should have_selector("tr##{user_activity.id}")
    end
  end

  it 'should show the date above the activities for each day' do
    page.should have_content(UserActivity.first.created_at.localtime.strftime("%B %e, %Y").gsub('  ', ' '))
    page.should have_content(UserActivity.last.created_at.localtime.strftime("%B %e, %Y").gsub('  ', ' '))
  end

  it 'should show the time for each activity' do
    UserActivity.all.each do |user_activity|
      page.should have_content(user_activity.created_at.in_time_zone("Pacific Time (US & Canada)").strftime("%I:%M %p"))
    end
  end

  it 'should show the name of the user for each activity' do
    UserActivity.all.each do |user_activity|
      page.should have_content(user_activity.name)
    end
  end

  it 'should show the email of the user for each activity' do
    UserActivity.all.each do |user_activity|
      page.should have_content(user_activity.email)
    end
  end

  it 'should show the action for each activity' do
    UserActivity.all.each do |user_activity|
      page.should have_content(user_activity.action)
    end
  end

  it 'should show the description for each activity' do
    UserActivity.all.each do |user_activity|
      page.should have_content(user_activity.description)
    end
  end

  describe "paging" do

    before do
      20.times do |i|
        Factory(:user_activity, :created_at => Time.now + 24.hours + (i + 10).minutes)
      end

      visit activity_stream_path
    end

    it 'should only show 20 records' do
      UserActivity.all.each_with_index do |user_activity, i|
        if i < 20
          page.should have_selector("tr##{user_activity.id}")
        else
          page.should_not have_selector("tr##{user_activity.id}")
        end
      end
    end

    it 'should show "more" button' do
      page.should have_selector('#more')
    end

    it 'should show more when "more" button is clicked' do
      click_link("more")

      UserActivity.all.each_with_index do |user_activity, i|
        if i < 40
          page.should have_selector("tr##{user_activity.id}")
        else
          page.should_not have_selector("tr##{user_activity.id}")
        end
      end
    end
  end
end