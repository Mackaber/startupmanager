require "spec_helper"

describe Api::V1::HypothesesController do

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = Factory(:confirmed_user)
    sign_in @user
  end

  describe "POST create" do

    before do
      @owner = Factory(:owner, :user => @user)
      @valid_params = Factory.attributes_for(:hypothesis, :project_id => @owner.project.id).merge({:format => :json} )
    end

    describe "with valid params" do

      it "creates a hypothesis" do
        expect { post :create, @valid_params}.to change { Hypothesis.count }.by(1)
      end

      it "does not create a hypothesis for a project the user is not a member of" do
        unrelated_project = Factory(:project)
        expect { post :create, @valid_params.merge({:project_id => unrelated_project.id})}.to_not change { ::Hypothesis.count }
      end
    end

    describe "with invalid params" do

      it "does not create a hypothesis" do
        expect { post :create, @valid_params.merge({:title => ''})}.to_not change { Hypothesis.count }
      end

      it "returns status 400" do
        post :create, @valid_params.merge({:title => ''})
        response.status.should == 400
      end

    end
  end
end