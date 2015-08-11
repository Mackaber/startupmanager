require "spec_helper"

describe ItemStatus do
  describe "the index operator - ItemStatus[:foo]" do

    it "returns the id for the corresponding status symbol" do
      ItemStatus[:unknown].should == 1
      ItemStatus[:valid].should == 2
      ItemStatus[:invalid].should == 3
    end

    it "does not hit the database on the second request for a key" do
      ItemStatus[:unknown] #first time
      ItemStatus.stub(:find_by_status)
      ItemStatus.should_not_receive(:find_by_status)
      ItemStatus[:unknown] #second time
    end
  end
end