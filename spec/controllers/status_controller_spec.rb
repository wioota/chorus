require 'spec_helper'

describe StatusController do
  describe "#show" do
    it "should return a 200 response" do
      get :show
      response.code.should == "200"
    end
  end
end