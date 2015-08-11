require 'spec_helper'

describe UserActivity do

  describe "truncation" do
    it "shortens the description down to 250 characters if it's longer" do
      user_activity = Factory(:user_activity, :description => "X" * 251)
      user_activity.description.length.should == 250
    end
  end
end
