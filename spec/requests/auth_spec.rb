require 'spec_helper'

describe "resources which require authentication" do
  let!(:user) { users(:default) }

  context "after the user has logged in" do
    before do
      post "/sessions", :session => { :username => user.username, :password => FixtureBuilder.password }
      response.should be_success
    end

    it "shows the resource" do
      get "/users"
      response.should be_success
    end

    context "then logged out" do
      before do
        delete "/sessions"
      end

      it "refuses to show the resource" do
        get "/users"
        response.code.should == "401"
      end
    end
  end

  context "when the user has never logged in" do
    it "refuses to show the resource" do
      get "/users"
      response.code.should == "401"
    end
  end
end
