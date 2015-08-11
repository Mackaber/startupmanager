require "spec_helper"

describe Box do
  it "loads data from seeds.rb" do
    Box.find_by_name("key_partners").should_not be_nil
    Box.find_by_name("key_activities").should_not be_nil
    Box.find_by_name("key_resources").should_not be_nil
    Box.find_by_name("value_propositions").should_not be_nil
    Box.find_by_name("customer_relationships").should_not be_nil
    Box.find_by_name("channels").should_not be_nil
    Box.find_by_name("customer_segments").should_not be_nil
    Box.find_by_name("cost_structure").should_not be_nil
    Box.find_by_name("revenue_stream").should_not be_nil
  end
end
