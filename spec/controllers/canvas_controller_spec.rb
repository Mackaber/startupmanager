require 'spec_helper'

describe CanvasController do

  describe "without a signed-in user" do
    it "get :show denies access and re-routes to login" do
      get :show, :project_id => 1
      response.should redirect_to new_user_session_path
    end
  end

  describe "with signed-in user" do

    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = Factory(:confirmed_user)
      sign_in @user
    end

    describe "GET show" do
      before do
        @project_start = Date.parse('2000-01-31') # this is a Monday
        @project = Factory(:project, :created_at => @project_start)
        @owner = Factory(:owner, :user => @user, :project => @project)
      end

      it "assigns the correct project" do
        get 'show', :project_id => @project.id
        assigns(:project).should == @project
      end

      context "delta parameter " do
        it "assigns false to viewing_delta variable when the hide_delta parameter has a value" do
          get 'show', :project_id => @project.id, :hide_delta => true
          assigns(:viewing_delta).should be_false
        end

        it "assigns true to viewing_delta variable when the hide_delta parameter is not passed" do
          get 'show', :project_id => @project.id
          assigns(:viewing_delta).should be_true
        end

      end

      describe "date calculations" do
        before do
          @utc_end_of_week = LeanLaunchLab::Application.utc_end_of_week
        end

        describe "no date parameter passed in" do
          it "assigns this_week as end of this current week if no date is passed" do
            get 'show', :project_id => @project.id
            assigns(:this_week).should == @utc_end_of_week
          end

          it "assigns nil to the date for next week if no date is passed in" do
            get 'show', :project_id => @project.id
            assigns(:next_week).should == nil
          end

          it "assigns to the date for previous week if no date passed in, but there is, in fact, a previous week" do
            get 'show', :project_id => @project.id
            assigns(:previous_week).should == @utc_end_of_week - 7
          end

          it "assigns nil to the date for the prev week if there is no previous week" do
            @project.update_attribute(:created_at, Time.now.utc.to_date)
            get 'show', :project_id => @project.id
            assigns(:previous_week).should == nil
          end
        end

        describe "a valid date parameter which is a date object" do
          it "assigns the correct dates to correspond to the previous and next weeks" do
            a_day_in_week_two = @project_start + 10.days
            get 'show', :project_id => @project.id, :date => a_day_in_week_two
            end_of_first_week = Date.parse('2000-02-06')
            end_of_third_week = end_of_first_week + 14
            assigns(:previous_week).should == end_of_first_week
            assigns(:next_week).should == end_of_third_week
          end

          it "assigns nil to the date for next week if the date passed in is from the current week" do
            get 'show', :project_id => @project.id, :date => Time.now.utc.to_date
            assigns(:next_week).should == nil
          end

          it "assigns week_ending_date if date passed" do
            get 'show', :project_id => @project.id, :date => Date.parse('2000-02-10')
            assigns(:this_week).should == Date.parse('2000-02-13')
          end

          it "assigns week_ending_date as end of this week if the date passed in is in the future" do
            @project.update_attribute(:created_at, Date.today)
            get 'show', :project_id => @project.id, :date => Date.today + 1000.days
            assigns(:this_week).should == @utc_end_of_week
          end

          it "assigns nil to the date for the prev week button if there is no previous week" do
            @project.update_attribute(:created_at, @project_start)
            get 'show', :project_id => @project.id, :date => @project_start
            assigns(:previous_week).should == nil
          end
        end

        describe "a string is passed in the date parameter" do
          it "correctly parses a valid string" do
            a_day_in_week_two = @project_start + 10.days
            get 'show', :project_id => @project.id, :date => a_day_in_week_two.to_s
            end_of_first_week = Date.parse('2000-02-06')
            end_of_third_week = end_of_first_week + 14
            assigns(:previous_week).should == end_of_first_week
            assigns(:next_week).should == end_of_third_week
          end

          it "acts as if no date was passed in when given a garbage string" do
            @project.update_attribute(:created_at, Date.today)
            get 'show', :project_id => @project.id, :date => "This string definitely does not represent a date"
            assigns(:this_week).should == @utc_end_of_week
          end
        end
      end
    end
  end

end
