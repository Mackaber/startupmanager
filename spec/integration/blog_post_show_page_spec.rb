require "spec_helper"

describe "Blog Post Show page" do

  before do
    @user = Factory(:confirmed_user)
  end

  context 'authenticated user' do
    before do
      visit user_session_path
      fill_in 'Email', :with => @user.email
      fill_in 'user_password', :with => @user.password
      click_link "Sign In"

      current_path.should == projects_path
    end

    after do
      visit destroy_user_session_path #sign out
    end

    describe "user is a member of the project" do

      describe "Role restricted actions" do

        def setup_member_and_project level
          if level == "Owner"
            member = Factory(:owner, :user => @user)
          else
            owner = Factory(:owner)
            member = Factory(:member_who_has_joined_project, :project => owner.project, :user => @user, :level => level)
          end
          @project = member.project
          member
        end

        %w(Admin Normal Viewer).each do |level|
          context "level is #{level}" do
            before do
              member = setup_member_and_project(level)
              @blog_post = Factory(:blog_post, :member => member, :body => 'the_post_body')
              @comment = Factory(:comment, :blog_post => @blog_post, :body => 'the_comment_body')
              visit projects_blog_post_path(@project.id, @blog_post.id, :hide_rte => "true")
            end

            if level == "Viewer"
              it 'should NOT show add feedback form' do
                page.should_not have_selector('#comment_body')
              end
              it 'should NOT display existing feedback' do
                page.should_not have_selector('div.comment')
                page.should_not have_content(@comment.body)
              end
              it 'should display existing blog posts' do
                page.should have_content(@blog_post.body)
                page.should have_selector('div.post')
                page.evaluate_script("$('div.preview-text').html()").should_not be_nil
                page.evaluate_script("$('div.preview-text').html()").should =~ /#{@blog_post.body}/
              end
            else
              it 'should show feedback entry' do
                page.should have_selector('#comment_body')
              end
            end
          end
        end

      end

      describe "UI" do

        before do
          @owner = Factory(:owner, :user => @user)
          @blog_post = Factory(:blog_post, :member => @owner)
        end

        describe "... more link" do
          before do
            @blog_post.update_attribute(:body, "XXXXX XXXXX " * 25 + "YYYYY YYYYY " * 25)
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
          end

          it "starts with div.expanded hidden and truncated div shown" do
            page.evaluate_script("$('div.toggle div.preview-text').css('display')").should_not == 'none'
            page.evaluate_script("$('div.toggle div.full-view').css('display')").should == 'none'
          end

          it "shows div.expanded and div.truncated after clicking 'more'" do
            click_link("( more )")
            sleep(0.8)
            page.evaluate_script("$('div.toggle div:first').css('display')").should == 'none'
            page.evaluate_script("$('div.toggle div:nth-child(2)').css('display')").should_not == 'none'
          end
        end

        describe "comment link" do
          it "shows add comment form when clicked" do
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
            page.evaluate_script("$('div.show-comment-form').css('display')").should == 'none'
            click_link('comment')
            sleep(1)
            page.evaluate_script("$('div.show-comment-form').css('display')").should_not == 'none'
          end
        end

        describe "save draft" do
          it "reports error and does not save draft without project selected" do
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
            click_link "All Projects"
            wait_until { page.has_content? "ALL UPDATES" }
            click_link "New Blog Post"
            click_link "Save Draft"
            page.should have_content "You must select a project"
            page.should have_selector('input#text-title')
          end

          it "saves a draft with project selected" do
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
            click_link @owner.project.name
            wait_until { page.has_content? @blog_post.subject }
            click_link "New Blog Post"
            click_link "Save Draft"
            page.should have_content "draft saved successfully"
            page.should have_content "Drafts"
          end
        end

        describe "publishing a draft" do
          before do
            draft_to_publish = BlogPost.new(:published_at => nil, :subject => 'test_draft_post', :body => 'The body', :member => @owner, :project => @owner.project)
            draft_to_publish.save(:validate => false)
            visit projects_path(:hide_rte => "true")
            click_link "Drafts"
            click_link "edit_post"
            click_link "Publish"
          end

          it "shows up in 'New Posts' view " do
            click_link 'New Posts'
            page.should have_content("ALL UPDATES")
            page.should have_content("test_draft_post")
          end

          it "does not show up in 'Drafts' view " do
            page.should have_no_content('Drafts')
          end
        end

        describe "drafts are not visible to other users" do
          before do
            user_draft = Factory(:blog_post, :published_at => nil, :subject => 'user2 should never see this', :body => 'The body', :member => @owner, :project => @owner.project)
            visit destroy_user_session_path #sign out
            user2 = Factory(:confirmed_user)
            member2 = Factory(:member_who_has_joined_project, :user => user2, :project => @owner.project)
            user2_draft = Factory(:blog_post, :published_at => nil, :subject => 'this makes draft view available', :body => 'The body', :member => member2, :project => @owner.project)
            visit user_session_path
            fill_in 'Email', :with => user2.email
            fill_in 'user_password', :with => user2.password
            click_link "Sign In"
            visit projects_path(:hide_rte => "true")
          end
          after do
            visit destroy_user_session_path #sign out
          end

          ["Drafts", "All Projects", "New Posts"].each do |view|
            it "does not show up in #{view}" do
              click_link view
              page.should have_no_content "user2 should never see this"
            end
          end

          it "does not show up in the project view" do
            click_link @owner.project.name
            page.should have_no_content "user2 should never see this"
          end
        end

        describe "displaying drafts" do
          before do
            draft = BlogPost.new(:published_at => nil, :subject => 'test_draft_post', :body => '', :member => @owner, :project => @owner.project)
            draft.save(:validate => false)
            visit projects_path(:hide_rte => "true")
          end

          it "shows up in Drafts" do
            click_link 'Drafts'
            wait_until { page.has_content? 'DRAFTS' }
            page.should have_content "#{@owner.project.name} UNPUBLISHED by #{@owner.user.name}"
            page.should have_content "test_draft_post"
          end

          it "does not show up in ALL Projects" do
            click_link 'All Projects'
            page.should have_no_content "test_draft_post"
          end

          it "does not show up in New Posts" do
            click_link 'New Posts'
            page.should have_no_content "test_draft_post"
          end

          it "does not show up in its project" do
            click_link @owner.project.name
            page.should have_no_content "test_draft_post"
          end
        end

        describe 'cancel edit' do
          it 'should redirect to current page' do
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
            current_path.should == projects_blog_post_path(@owner.project.id, @blog_post.id)
            page.should have_no_selector("form.new-post")
            click_link("edit_post")
            page.should have_selector("form.new-post")
            click_link 'Cancel'
            page.should have_no_selector("form.new-post")
          end
        end

        describe 'sanitization' do
          it 'should not render javascript in read only view' do
            pending "sanitation is currently not being used"
            @blog_post.update_attribute('body', %Q{<img onload="js:alert('test')"/>})
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
            page.should_not have_selector(%Q{img [onload="js:alert('test')"]})
          end
        end

        describe 'feedback' do
          it 'should list comments' do
            comment = Factory(:comment, :blog_post => @blog_post, :body => "I like turtles")
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
            page.should have_content(comment.body)
          end

          it 'should have textarea to leave a comment' do
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
            page.should have_selector('#comment_body')
          end

          it "lists the authors and counts of unread feedback" do
            pending "not currently trying to do this"
            @blog_post.update_attribute(:created_at, Date.today - 2.days)
            member = Factory(:member, :project => @owner.project)
            member.user.update_attribute(:name, 'Snoopy')
            comment = Factory(:comment, :blog_post => @blog_post, :member => member) #, :created_at => Time.now + 1.minute)
            comment2 = Factory(:comment, :blog_post => @blog_post, :member => member) #, :created_at => Time.now + 1.minute)
            visit project_path(@owner.project.id, :hide_rte => "true")
            page.should have_content "Snoopy(2)"
          end

          it 'should display comment after a comment has been posted' do
            visit projects_blog_post_path(@owner.project.id, @blog_post.id, :hide_rte => "true")
            click_link("comment")
            fill_in('comment_body', :with => "I like pizza")
            click_button('Submit')
            current_path.should == projects_blog_post_path(@owner.project.id, @blog_post.id)
            page.should have_content("I like pizza")
          end
        end

      end

    end
  end
end
