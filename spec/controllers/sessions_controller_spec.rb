require 'spec_helper'
require 'timecop'

describe SessionsController do
  describe "#create" do
    let(:user) { users(:admin) }
    let(:params) { {:username => user.username, :password => FixtureBuilder.password} }

    describe "with the correct credentials" do
      it "succeeds" do
        post :create, params
        response.code.should == "201"
      end

      it "creates a new session" do
        expect { post :create, params }.to change(Session, :count).by(1)
        Session.last.user.should == user
      end

      it "adds the session_id to the session" do
        expect { post :create, params }.to change(Session, :count).by(1)
        session[:chorus_session_id].should == Session.last.session_id
      end

      it "should present the session" do
        mock_present do |model|
          model.should be_a Session
          model.user.should == user
        end
        post :create, params
      end
    end

    context "with correct credentials for a deleted user" do
      let(:user) {users :evil_admin}
      before do
        user.destroy
        post :create, params
      end

      it "fails with response code 401" do
        response.code.should == "401"
      end
    end

    describe "with incorrect credentials" do
      let(:params) { {:username => user.username, :password => 'badpassword'} }
      before do
        post :create, params
      end

      it "fails with response code 401" do
        response.code.should == "401"
      end

      it "includes details of invalid credentials" do
        decoded_errors.fields.username_or_password.INVALID.should == {}
      end
    end
  end

  describe "#show" do
    context "When logged in" do
      let(:user) { users(:default) }

      before do
        log_in user
        get :show
      end

      it "should present the session" do
        mock_present do |model|
          model.should be_a Session
          model.user.should == user
        end
        get :show
        response.code.should == "200"
      end

      generate_fixture "session.json" do
        get :show
      end
    end

    context "when not logged in" do
      before do
        get :show
      end
      it "returns 401" do
        response.code.should == "401"
      end
    end
  end

  describe "#destroy" do
    it "returns no content" do
      delete :destroy
      response.code.should == "204"
      response.body.strip.should be_empty
    end

    it "clears the session" do
      log_in users(:owner)
      delete :destroy
      response.code.should == "204"
      session[:user_id].should_not be_present
      session[:expires_at].should_not be_present
    end
  end
end
