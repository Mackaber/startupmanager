require "spec_helper"

describe "Project page" do

  before do
    @user = Factory(:confirmed_user)
  end

  context 'authenticated user' do

    before do
      visit destroy_user_session_path #sign out
      visit user_session_path
      fill_in 'Email', :with => @user.email
      fill_in 'user_password', :with => @user.password
      click_link "Sign In"

      current_path.should == projects_path
    end

    after(:all) do
      visit destroy_user_session_path #sign out
    end

    context 'user is member of project' do

      def setup_member_and_project level
        owner = Factory(:owner)
        member = Factory(:member_who_has_joined_project, :project => owner.project, :user => @user, :level => level)
        @project = member.project
        member
      end

      describe 'canvas' do

        describe "showing canvas" do
          before do
            @owner = Factory(:owner, :user => @user)
            @project1 = @owner.project
            member = Factory(:member_who_has_joined_project, :user => @user, :project => Factory(:project))
            @project2 = member.project
            @canvas_item1 = Factory(:canvas_item, :project => @project2, :text => 'P2CI')
            visit current_user_path
          end
          context "when clicking green icon in  project list" do
            context "with 'All Projects' selected" do
              it "shows the canvas" do
                click_link("All Projects")
                find("li[project_id='#{@project2.id}'] a.info").click()
                page.should have_content("P2CI")
              end
            end
            context "with 'All Projects' NOT selected" do
              it "shows the canvas" do
                click_link(@project1.name)
                find("li[project_id='#{@project2.id}'] a.info").click()
                page.should have_content("P2CI")
              end
            end
          end
        end

        describe 'boxes' do
          before do
            @owner = Factory(:owner, :user => @user)
            @project = @owner.project
          end

          it 'loads with page as a hidden div' do
            visit project_path(@project, :hide_rte => 'true')
            page.should have_selector('div.canvas-holder')
            page.evaluate_script("$('div#canvas_universe').css('display')").should == 'none'
          end

          it 'should show each box' do
            visit project_path(@project, :hide_rte => "true")
            click_link('Show Canvas')
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            Box.all.each do |box|
              page.should have_selector("##{box.name}")
            end
          end
        end

        describe 'canvas items' do

          describe 'role restricted actions' do
            %w(Admin Normal Viewer).each do |level|
              context "role is #{level}" do
                before do
                  setup_member_and_project(level)
                  Box.all.each { |b| Factory(:canvas_item, :box => b, :project => @project) }
                  visit project_path(@project, :hide_rte => "true")
                  click_link('Show Canvas')
                  page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                end

                if level == "Viewer"
                  it 'should NOT show "new item" button' do
                    page.should_not have_selector(".new-item")
                  end

                  it 'should NOT show "edit item" button' do
                    page.should_not have_selector(".edit_item_button")
                  end

                  it 'should NOT show "delete item" button' do
                    page.should_not have_selector(".delete_item_button")
                  end

                  it 'should NOT show change status links ' do
                    page.should_not have_selector("ul.edit-status")
                  end

                else
                  it 'should show "new item" button' do
                    Box.all.each do |box|
                      page.should have_selector("##{box.name} .new-item")
                    end
                  end

                  it 'should show "edit item" button' do
                    Box.all.each do |box|
                      page.should have_selector("##{box.name} .edit_item_button")
                    end
                  end

                  it 'should show "delete item" button' do
                    Box.all.each do |box|
                      page.should have_selector(".delete_item_button")
                    end
                  end

                  it 'should show change status links ' do
                    Box.all.each do |box|
                      page.should have_selector("##{box.name} ul.edit-status")
                    end
                  end
                end
              end
            end
          end

          describe "canvas_item UI" do
            before do
              setup_member_and_project("Admin")
              canvas_item1 = Factory(:canvas_item, :project => @project)
              @canvas_item = canvas_item1.create_updated
              @project.reload

              Factory(:canvas_item, :project => @project)
              @box = @canvas_item.box
              visit project_path(@project, :hide_rte => "true")
              click_link('Show Canvas')
              page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            end

            it 'should show canvas items in boxes' do
              @project.canvas_items_for_utc_date(Time.now.utc, @box).each do |canvas_item|
                page.should have_selector("li[canvas_item_id='#{canvas_item.id}']")
                page.should have_selector("div##{@box.name}:contains('#{canvas_item.text}')")
              end
            end

            describe 'new button' do
              it 'should show the "new item" button for each box' do
                Box.all.each do |box|
                  page.should have_selector("#facebox ##{box.name} .new-item")
                end
              end

              it "shows the new canvas item form when the 'new item' button is clicked" do
                page.evaluate_script("$('div##{@box.name} .new_item_div').css('display')").should == 'none'
                find("div##{@box.name}").click_link("new item")
                textarea_selector = "div##{@box.name} textarea#canvas_item_text"
                wait_until { page.has_selector?(textarea_selector) }
                page.evaluate_script("$(\"div##{@box.name} form[action='#{canvas_items_path}']\").closest('.new_item_div').css('display')").should_not == 'none'
                page.should have_selector("#facebox form[action='#{canvas_items_path}']")
              end

              describe "new canvas item form" do
                before do
                  find("div##{@box.name}").click_link("new item")
                  sleep(0.2)
                end

                it "user presses 'Save' - it closes the form and adds a record with the expected value" do
                  fill_in 'canvas_item_text', :with => "test item"
                  click_button 'Save'
                  sleep(0.2)
                  page.should have_selector("#facebox div##{@box.name} div.new_item_div[style='display: none; ']")
                  page.should have_content('test item')
                end

                it "user presses 'Cancel' - it closes the form and does NOT add a record" do
                  fill_in 'canvas_item_text', :with => "test item"
                  click_button 'new_canvas_item_cancel'
                  sleep(1)
                  current_path.should == project_path(@project)
                  page.should_not have_content("test item")
                end
              end
            end

            context "the edit block" do
              it 'should show the edit/update/delete controls for each canvas item' do
                @project.canvas_items_for_utc_date(Time.now.utc, @box).each do |canvas_item|
                  page.should have_selector("#facebox li[canvas_item_id='#{canvas_item.id}'] .canvas_item_edit_update_btns")
                end
              end

              describe "edit button" do
                it 'should show the edit form when the edit button is clicked' do
                  page.evaluate_script("$('div##{@box.name} .edit_canvas_item').css('display')").should == 'none'
                  find("li[canvas_item_id='#{@canvas_item.id}']").click_button("edit")
                  selector = ("div##{@box.name} .edit_canvas_item")
                  wait_until { has_selector?(selector) }
                  page.evaluate_script("$(\"#facebox form[action='/canvas_items/1-some-item-1'] .edit_canvas_item\").css('display')").should_not == 'none'
                  page.should have_selector("#facebox form[action='#{canvas_item_path(@canvas_item)}']")
                end

                describe "edit canvas item form" do
                  before do
                    find("li[canvas_item_id='#{@canvas_item.id}']").click_button("edit")
                    sleep(1)
                    fill_in 'canvas_item_text', :with => "new improved content"
                  end

                  describe "user presses 'Save'" do
                    before do
                      @old_id = @canvas_item.id
                      click_button 'Save'
                      sleep(0.2)
                    end

                    it "the form closes and the text changes" do
                      page.should_not have_selector("#facebox form[action='#{canvas_items_path}']")
                      page.should have_content('new improved content')
                    end

                    it "changes the value of the canvas_item_id attribute on the page to the newer id" do
                      new_item = CanvasItem.last
                      new_item.id.should_not == @old_id
                      page.should have_selector("#facebox li.canvas_item [canvas_item_id='#{new_item.id}']")
                    end
                  end

                  describe "user presses 'Cancel'" do
                    it "the form closes and the text does NOT change" do
                      click_button 'Cancel'
                      sleep(0.2)
                      page.should_not have_selector("#facebox form[action='#{canvas_items_path}']")
                      page.should have_content(@canvas_item.text)
                    end
                  end
                end
              end

              describe "update status" do
                it "changes the css class that designates the color when canvas_item existed AT page load" do
                  find("li[canvas_item_id='#{@canvas_item.id}']").click_link("invalid")
                  wait_until { page.evaluate_script("$('li[canvas_item_id=\"#{CanvasItem.last.id}\"]').hasClass('red')") == true }
                  page.evaluate_script("$('li[canvas_item_id=\"#{CanvasItem.last.id}\"]').hasClass('red')").should == true
                end

                it "changes the css class that designates the color when canvas_item created AFTER page load" do
                  CanvasItem.delete_all
                  visit project_path(@project, :hide_rte => "true")
                  click_link('Show Canvas')
                  page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                  find("div##{@box.name}").click_link("new item")
                  fill_in('canvas_item_text', :with => 'some text')
                  click_button('Save')
                  click_link("invalid")
                  wait_until { page.evaluate_script("$('li.canvas_item').first().hasClass('red')") == true }
                  page.evaluate_script("$('li.canvas_item').first().hasClass('red')").should be_true
                end

                it "changes the value of the canvas_item_id attribute on the page to the newer id" do
                  pending "rake spec hanging on this test"
                  @old_id = @canvas_item.id
                  find("li[canvas_item_id='#{@old_id}']").click_link("valid")
                  new_item = CanvasItem.last
                  new_item.id.should_not == @old_id
                  selector = "#facebox li.canvas_item[canvas_item_id='#{new_item.id}']"
                  page.should have_selector(selector)
                end
              end

              describe "delete" do
                it "deletes the item" do
                  item_text = @canvas_item.text
                  find("#facebox li[canvas_item_id='#{@canvas_item.id}']").click_button 'delete'
                  sleep(0.4) # need a longer delay here because of call to canvas_item.slideUp in our jQuery code.
                  current_path.should == project_path(@project)
                  page.should_not have_selector("#facebox div##{@box.name}:contains('#{item_text}')")
                  visit project_path(@project, :hide_rte => "true")
                  click_link('Show Canvas')
                  wait_until { has_selector?('#facebox div.switcher') }
                  page.should_not have_selector("#facebox div##{@box.name}:contains('#{item_text}')")
                end
              end
            end
          end

          describe "history" do

            {Time.parse("2011-08-07 23:50:00 UTC") => "10 minutes before midnight on Sunday, UTC",
             Time.parse("2011-08-08 00:10:00 UTC") => "10 minutes after midnight on Monday, UTC",
             Time.parse("2011-08-10 12:00:00 UTC") => "noon on Wednesday, UTC"}.each_pair do |simulated_utc_time, time_description|

              describe "Running this test as if current time were #{simulated_utc_time} - #{time_description}" do
                before(:each) do
                  Timecop.travel simulated_utc_time
                  @utc_end_of_week = LeanLaunchLab::Application.utc_end_of_week
                  @project = Factory(:project, :created_at => Time.now - 14.days)
                  @owner = Factory(:owner, :user => @user, :project => @project)
                  @canvas_item = Factory(:canvas_item, :project => @project)
                end
                after(:all) do
                  Timecop.return
                end

                describe "how the view looks different" do
                  it "does not show the add item button" do
                    visit project_path(@project, :hide_rte => "true")
                    click_link('Show Canvas')
                    wait_until { page.has_selector?("#facebox li[canvas_item_id='#{@canvas_item.id}']") }
                    click_link('prev')
                    page.should have_no_selector("#facebox a.new-item")
                  end

                  it "does not show canvas items from the future" do
                    canvas_item = Factory(:canvas_item, :project => @project, :text => 'something unique')
                    visit project_path(@project, :hide_rte => "true", :date => (Date.today - 8.days))
                    click_link('Show Canvas')
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    click_link('prev')
                    page.should have_no_content('something unique')
                  end
                end

                describe "handling UTC dates" do
                  it "handles dates near both sides of the week end time" do
                    sunday_midnight = @utc_end_of_week - 1.week + 1.day
                    end_of_previous_week = sunday_midnight - 1.minute
                    beginning_of_this_week = sunday_midnight + 1.minute
                    Factory(:canvas_item, :text => 'last weeks item', :project => @project, :created_at => end_of_previous_week)
                    @project.update_attribute(:created_at, sunday_midnight - 2.weeks)
                    Factory(:canvas_item, :created_at => beginning_of_this_week, :project => @project, :text => 'this weeks item')

                    visit project_path(@project, :hide_rte => "true")
                    click_link('Show Canvas')
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    click_link('prev')
                    sleep(1)
                    page.should have_content('last weeks item')
                    page.should_not have_content('this weeks item')
                    visit project_path(@project, :hide_rte => "true")
                    click_link('Show Canvas')
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    page.should have_content('this weeks item')
                    page.should have_content('last weeks item')
                  end
                end

                describe "keeps delta parameter when " do
                  before do
                    @project.update_attribute(:created_at, Date.today - 10.weeks)
                  end
                  %w(first last next prev).each do |button|
                    it "#{button} button clicked" do
                      visit project_path(@project, :hide_rte => "true") #, :date => Date.today - 5.weeks)
                      click_link('Show Canvas')
                      page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                      sleep(1)
                      click_link('prev')
                      page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                      sleep(1)
                      page.find('.highlight-changes-on').click
                      page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                      sleep(1)
                      click_link(button)
                      page.should have_content "Highlight Changes: OFF"
                    end
                  end
                end

                describe "displays the correct date and week number" do
                  before do
                    @project.update_attribute(:created_at, @utc_end_of_week - 4.weeks)
                    visit project_path(@project, :hide_rte => "true")
                    click_link('Show Canvas')
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    @week4_date_str = (@utc_end_of_week - 13.days).strftime("%b %d").gsub(' 0', ' ') + ' - ' +
                        (@utc_end_of_week - 7.days).strftime("%b %d").gsub(' 0', ' ')
                  end

                  it "shows week 4 " do
                    date_str = (@utc_end_of_week - 6.days).strftime("%b %d").gsub(' 0', ' ') + ' - ' +
                        (@utc_end_of_week).strftime("%b %d").gsub(' 0', ' ')
                    page.should have_content(date_str)
                    page.should have_content("Week 5")
                  end

                  it "shows week 1 with 'prev' button" do
                    click_link("prev")
                    page.should have_content(@week4_date_str)
                    page.should have_content("Week 4")
                  end

                  it "shows week 1 with 'first' button" do
                    date_str = (@utc_end_of_week - 34.days).strftime("%b %d").gsub(' 0', ' ') + ' - ' +
                        (@utc_end_of_week - 28.days).strftime("%b %d").gsub(' 0', ' ')
                    click_link("first")
                    page.should have_content(date_str)
                    page.should have_content("Week 1")
                  end

                  it "shows week 4 with 'next' button" do
                    click_link("prev")
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    sleep(1)
                    click_link("prev")
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    sleep(1)
                    click_link("next")
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    sleep(1)
                    page.should have_content(@week4_date_str)
                    page.should have_content("Week 4")
                  end

                  it "shows current week with 'last' button" do
                    visit project_path(@project, :hide_rte => "true")
                    click_link('Show Canvas')
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    sleep(1)
                    week_range_text = page.evaluate_script("$('div.date-holder span').html()")
                    week_number_text = page.evaluate_script("$('div.date-holder strong').html()")
                    click_link("first")
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    sleep(1)
                    click_link("last")
                    page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
                    sleep(1)
                    page.should have_content(week_range_text)
                    page.should have_content(week_number_text)
                  end
                end
              end
            end
          end
        end

        describe "delta - changes between this week and the previous week" do
          before do
            @owner = Factory(:owner, :user => @user)
            @project = @owner.project
            @project.update_attribute(:created_at, Date.today - 2.weeks)
            visit project_path(@project, :hide_rte => "true")
            click_link('Show Canvas')
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
          end

          it "has a button that turns off highlight changes" do
            page.should have_selector("#facebox a.highlight-changes-on")
          end

          it "changes Un-highlight Changes button to highlight Changes button when clicked" do
            #page.execute_script("LEAN_LAUNCH_LAB.canvas_url=''") #sometimes this seems to cause js error/ capybara broken pipe
            page.find('#facebox a.highlight-changes-on').click()
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            page.should have_selector("#facebox a.highlight-changes-off")
          end

          it "shows :full outlines in 'highlight changes' mode and new item present" do
            Factory(:canvas_item, :project => @project)
            click_link('Show Canvas')
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            page.should have_selector('#facebox li.canvas_item.full')
          end

          it "shows :full outlines and strikeout when deleted item present" do
            item = Factory(:canvas_item, :project => @project, :created_at => Date.today - 10.days)
            item.create_updated(:deleted => true)
            click_link('Show Canvas')
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            page.should have_selector('#facebox li.canvas_item.full')
            page.should have_selector('#facebox span.strikeout')
          end

          it "shows :three_quarter outlines and strikeout when 'highlight changes' clicked with edited item present" do
            original_item = Factory(:canvas_item, :project => @project, :created_at => Date.today - 10.days)
            updated_item = original_item.create_updated(:text => 'the updated text')
            click_link('Show Canvas')
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            page.should have_selector("#facebox li[canvas_item_id='#{original_item.id}'].canvas_item.upper-three-quarters")
            page.should have_selector("#facebox li[canvas_item_id='#{original_item.id}'] span.strikeout")
            page.should have_selector("#facebox li[canvas_item_id='#{updated_item.id}'].canvas_item.lower-three-quarters")
          end

          it "doesn't show outlining when nothing changed" do
            Factory(:canvas_item, :project => @project, :created_at => Date.today - 1.week)
            click_link('Show Canvas')
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            page.should_not have_selector('#facebox li.canvas_item.full')
          end

          it "keeps the date query parameter when unhighlight changes clicked" do
            click_link("prev")
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            sleep(1)
            week = page.evaluate_script("$('#facebox div.date-holder strong').html()")
            page.find('#facebox .highlight-changes-on').click
            page.should have_selector('#facebox div.switcher') #causes it to wait up to two seconds for div to appear
            sleep(1)
            page.evaluate_script("$('#facebox div.date-holder strong').html()").should == week
          end
        end
      end

      describe 'project list pane' do
        it 'should show list of projects' do
          @user.projects.each do |project|
            page.should have_content(project.name)
            page.should have_selector("li [project_id='#{project.id}']")
          end
        end

        it 'should show the number of blog posts that need comment for each project' do
          @user.projects.each do |project|
            member = @user.membership_on(project)
            page.find("li [project_id='#{project.id}']").should have_content("(#{project.blog_post_needing_comment(member).count})")
          end
        end
      end

      describe 'comment view' do

        describe 'blog posts' do
          describe 'role restricted actions' do
            %w(Admin Normal Viewer).each do |level|
              context "role is #{level}" do
                before do
                  @member = setup_member_and_project(level)
                  Factory(:blog_post, :member => @member, :project => @project)
                  Factory(:blog_post, :member => @member, :project => @project)
                  visit project_path(@project, :hide_rte => "true")
                end

                if level == "Viewer"
                  it "should NOT allow blog post creation" do
                    page.click_link "New Blog Post"
                    page.should have_content "Sorry! You can't create new blog posts"
                  end

                  it 'should NOT show "edit post" buttons' do
                    page.should_not have_selector(".edit_post_button")
                  end

                  it 'should NOT show "delete" button' do
                    page.should_not have_selector(".delete_post_button")
                  end
                elsif level == "Admin" || level == 'Normal'
                  it "should creating new blog posts" do
                    page.click_link "New Blog Post"
                    page.should have_content "NEW BLOG POST"
                  end

                  it 'should show "edit post" buttons' do
                    page.should have_selector(".edit_post_button")
                  end

                  it 'should show "delete" button' do
                    page.should have_selector(".delete_post_button")
                  end
                end
              end
            end
          end

          describe 'blog post UI' do
            before do
              @owner = setup_member_and_project("Admin")
              
              Factory(:blog_post, :member => @owner, :project => @project)
              visit project_path(@project, :hide_rte => "true")
            end

            describe 'listing and editing' do

              it 'should show list of blog posts for the project' do
                @project.blog_posts.each do |blog_post|
                  page.should have_selector("div[blog_post_id='#{blog_post.id}']")
                  page.should have_content(blog_post.subject)
                end
              end

              it 'should show the first blog post' do
                page.should have_selector("div.post[blog_post_id='#{@project.blog_posts.first.id}']")
              end

              it 'should show edit button for the blog post' do
                page.find("div.post [blog_post_id='#{@project.blog_posts.first.id}']").should have_selector(".edit_post_button")
              end

              it 'should open the edit form and hide the list of posts when the edit post button is clicked' do
                blog_post = @project.blog_posts.first
                page.evaluate_script("$('div#all-posts').css('display')").should_not == 'none'
                page.evaluate_script("$('div#new_post').css('display')").should == 'none'
                find("div[blog_post_id='#{blog_post.id}']").click_link("edit_post")
                wait_until { page.evaluate_script("$('div#all-posts').css('display')") == 'none' }
                page.evaluate_script("$('div#new_post').css('display')").should_not == 'none'
                selector = "form#edit_blog_post_#{blog_post.id}"
                page.should have_selector(selector)
              end

              it 'should reload the blog post list when a blog post is saved' do
                blog_post = @project.blog_posts.first
                orig_subject = blog_post.subject
                find("div[blog_post_id='#{blog_post.id}']").click_link("edit_post")
                fill_in "blog_post[subject]", :with => "new subject"
                click_link('Publish')
                page.should have_content("new subject")
                page.should have_no_content(orig_subject)
              end

              it 'should reload the project page when the cancel button is clicked' do
                blog_post = @project.blog_posts.first
                orig_subject = blog_post.subject
                find("div[blog_post_id='#{blog_post.id}']").click_link("edit_post")
                fill_in "blog_post[subject]", :with => "new subject"
                click_link 'Cancel'
                page.should have_content(orig_subject)
                page.should_not have_content("new subject")
              end

              it 'should delete the post when the delete button is clicked' do
                blog_post = @project.blog_posts.first
                subject = blog_post.subject
                find("div[blog_post_id='#{blog_post.id}']").click_button("delete")
                current_path.should == project_path(@project)
                page.should_not have_content(subject)
              end

              it 'should not display the ask after the blog post is saved if no value was entered' do
                find('a.edit_post_button').click()
                fill_in 'blog_post[body]', :with => "the new test body"
                fill_in 'blog_post[the_ask]', :with => ""
                click_link('Publish')
                page.should_not have_content("The Ask")
              end
            end

            describe 'creating' do
              it "pressing the 'new post' button brings up the blog entry form" do
                page.evaluate_script("$('#new_post').css('display')").should == 'none'
                click_link('New Blog Post')
                page.should have_content('NEW BLOG POST')
                page.evaluate_script("$('#new_post').css('display')").should_not == 'none'
              end

              it 'should reload the project page when a blog post has been created' do
                click_link('New Blog Post')
                page.should have_content('NEW BLOG POST') #wait for page to load
                fill_in 'blog_post[subject]', :with => "test subject"
                fill_in 'blog_post[body]', :with => "test body"
                click_link('Publish')
                page.should have_content("test subject")
              end

              it 'does not submit if any key learning exceeds 250 characters' do
                click_link('New Blog Post')
                fill_in 'blog_post[subject]', :with => "test subject"
                fill_in 'blog_post[body]', :with => "test body"
                fill_in 'learnings', :with => 'X' * 252
                click_link('Publish')
                page.should have_content("Key Learning cannot exceed 250 characters")
              end

              it 'submits if individual key learning less than 250 characters' do
                click_link('New Blog Post')
                fill_in 'blog_post[subject]', :with => "test subject"
                fill_in 'blog_post[body]', :with => "test body"
                fill_in 'learnings', :with => "#{'X' * 248} \n #{'X' * 248}"
                click_link('Publish')
                page.should have_content("Blog post created successfully")
              end

              it 'does not submit if title is blank' do
                click_link('New Blog Post')
                fill_in 'blog_post[body]', :with => "test body"
                click_link('Publish')
                page.should have_content("Title cannot be blank")
              end

              it 'should reload the project page when the cancel button is clicked' do
                visit project_path(@project, :hide_rte => "true")
                click_link('New Blog Post')
                fill_in 'blog_post[subject]', :with => "test subject"
                fill_in 'blog_post[body]', :with => "test body"
                click_link('Cancel')
                page.should_not have_content("test subject")
              end

              context "learnings" do

                it "displays learning's when they are present" do
                  click_link('New Blog Post')
                  fill_in 'blog_post[subject]', :with => "test subject"
                  fill_in 'blog_post[body]', :with => "test body"
                  fill_in 'learnings', :with => "test learning"
                  click_link('Publish')
                  page.should have_content("test learning")
                end

                it "does not display learning box when no learning's are present" do
                  click_link('New Blog Post')
                  fill_in 'blog_post[subject]', :with => "test subject"
                  fill_in 'blog_post[body]', :with => "test body"
                  click_link('Publish')
                  page.should have_no_content("Key Learnings")
                end

              end

              context "associated canvas items" do
                before do
                  @item1 = Factory(:canvas_item, :box => Box.find(1), :text => "item1", :project => @project)
                  @item2 = Factory(:canvas_item, :box => Box.find(2), :text => "item2", :project => @project)
                  @item3 = Factory(:canvas_item, :box => Box.find(3), :text => "item3", :project => @project)

                  visit project_path(@project, :hide_rte => "true")
                  click_link('New Blog Post')
                  fill_in 'blog_post[subject]', :with => "test subject"
                  fill_in 'blog_post[body]', :with => "test body"
                  click_link "Link Blog Post to Canvas Item(s)"
                  wait_until { page.has_content? "Select 1 or more canvas items" }
                  page.execute_script("$('#facebox li[canvas_item_id=\"#{@item1.id}\"]').click()")
                  wait_until { has_selector?('.item-selected') }
                end

                it 'associates canvas items with posts' do
                  page.execute_script("$('#facebox #selector-canvas-buttons input[type=\"submit\"]').click()")
                  page.should have_content(Box.find(1).label)
                  page.should have_content("item1")
                end

                it 'creates the association' do
                  page.execute_script("$('#facebox #selector-canvas-buttons input[type=\"submit\"]').click()")
                  click_link('Publish')
                  wait_until { page.has_content? "Blog post created successfully" }
                  BlogPost.last.post_items.count.should == 1
                end

                it "allows editing of associations" do
                  page.execute_script("$('#facebox #selector-canvas-buttons input[type=\"submit\"]').click()")
                  click_link('Publish')
                  click_link('edit_post')
                  page.find("div#associated-items").should have_content("item1")
                end

                it 'can add then remove associated canvas items' do
                  page.execute_script("$('#facebox #selector-canvas-buttons input[type=\"submit\"]').click()")
                  click_link('Publish')
                  click_link('edit_post')
                  click_link "Link Blog Post to Canvas Item(s)"
                  wait_until { page.has_content? "Select 1 or more canvas items" }
                  page.execute_script("$('#facebox li[canvas_item_id=\"#{@item1.id}\"]').click()")
                  wait_until { has_no_selector?('#facebox .item-selected') }
                  page.execute_script("$('#facebox #selector-canvas-buttons input[type=\"submit\"]').click()")
                  click_link('Publish')
                  wait_until { page.has_no_content? "Publish" }
                  BlogPost.last.post_items.count.should == 0
                end

                it "doesn't associate canvas items when cancel is pressed" do
                  page.execute_script("$('#facebox #selector-canvas-buttons input[type=\"reset\"]').click()")
                  wait_until { has_no_selector?('#facebox #selector-canvas-buttons input[type=\"submit\"]') }
                  page.should have_no_selector("#associated-items li")
                end
              end
            end

            describe "comments" do
              before do
                fill_in 'comment_body', :with => "test comment"
                click_button 'Submit'
              end

              it "creates new comment" do
                page.should have_selector(".comments span.info")
                page.should have_content('test comment')
              end

              describe "new comments" do

                it "marks new comments with 'NEW'" do
                  sleep(1)
                  page.should have_content('NEW')
                end

                it "gives new comments a class of highlight-new" do
                  page.should have_selector('.comments .highlight-new')
                end
              end
            end
          end
        end
      end
    end

    context 'user is not a member of the project' do
      before do
        unrelated_owner = Factory(:owner)
        @unrelated_project = unrelated_owner.project
      end

      context "user is a member of some other project" do
        before do
          click_link('New Project')
          page.should have_content('PROJECT NAME') #wait for page to load
          fill_in 'PROJECT NAME', :with => "#{@user.name}'s project"
          choose('project_members_attributes_0_role_name_founder')
          click_button 'Create Project'
          members_heading = "#{@user.name}'s project members".upcase
          page.should have_content members_heading
          new_project = Project.last
          @users_project_path = "/projects/#{new_project.to_param}"
          current_path.should == @users_project_path
        end

        it "is redirected back to their last visited project" do
          pending
          visit project_path(@unrelated_project, :hide_rte => "true")
          current_path.should == @users_project_path
        end
      end
    end
  end
end
