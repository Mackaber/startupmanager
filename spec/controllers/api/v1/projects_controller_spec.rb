require "spec_helper"

describe Api::V1::ProjectsController do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = Factory(:confirmed_user)
    sign_in @user
  end

  describe "get: show" do

    before do
      owner = Factory(:owner, :user => @user)
      @hypothesis = Factory(:hypothesis, :project => owner.project)
      get :show, :id => owner.project.to_param, :format => :json
    end

    it "has hypotheses in the response" do
      response.body.should =~ /\"hypotheses\":\[/
    end

    [ :created_by_member_id, :description, :position, :project_id, :title].each do |attr|
      it "has #{attr} in the response" do
        response.body.should =~ /#{@hypothesis[attr]}/
      end
    end

    it "has created_at as an integer" do
      response.body.should =~ /#{@hypothesis.created_at.to_i}/
    end
  end
end