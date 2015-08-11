require 'spec_helper'

describe Hypothesis do
  it "is valid" do
    Factory.build(:hypothesis).should be_valid
  end
end