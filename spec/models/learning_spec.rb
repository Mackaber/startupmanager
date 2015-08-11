require 'spec_helper'

describe Learning do
  describe 'validations' do
    it "is valid" do
      learning = Learning.new(:blog_post => Factory(:blog_post), :content => "People like turtles")
      learning.should be_valid
    end

    it "factory is valid" do
      Factory.build(:learning).should be_valid
    end

    [:content].each do |att|
      it "is not valid without #{att}" do
        subject.should_not be_valid
        subject.errors[att].should_not be_empty
      end
    end

    it "is not valid if content is too long" do
      learning = Factory.build(:learning, :content => "X" * 251)
      learning.should_not be_valid
    end

  end
end
