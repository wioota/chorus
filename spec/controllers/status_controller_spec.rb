require 'spec_helper'

describe StatusController do
  describe "#show" do
    it "should return a 200 response" do
      get :show
      response.code.should == "200"
      JSON.parse(response.body)["status"].should == "Chorus is running"
    end
  end
end