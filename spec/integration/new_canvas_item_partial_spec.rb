require "spec_helper"

describe "New canvas item partial" do

  before do
    @owner = Factory(:owner)
    @user = @owner.user
    @project = @owner.project
    @box = Box.first
  end

  context 'authenticated user' do

    before do
      visit user_session_path
      fill_in 'Email', :with => @user.email
      fill_in 'Password', :with => @user.password
      click_link "Sign In"
      click_link @project.name
      current_path.should == project_path(@project)
    end

    after do
      visit destroy_user_session_path #sign out
    end

    it 'should have an item text box' do
      visit new_canvas_item_path(@project.id, @box.name)

      page.should have_selector('textarea#canvas_item_text')
      page.should have_selector("input#canvas_item_project_id[type='hidden'][value='#{@project.id}']")
      page.should have_selector("input#canvas_item_box_id[type='hidden'][value='#{@box.id}']")
    end
  end

end
