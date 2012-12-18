require 'spec_helper'

describe ImportConsole::ImportsController do
  #ignore_authorization!

  let(:user) { users(:admin) }

  before do
    log_in user
  end

  describe "#index" do
    context "when there are imports pending" do
      let(:pending_import) { imports(:one) }

      before do
        Import.where(:finished_at => nil).map do |import|
          import.update_attribute(:finished_at, Time.now)
        end
        pending_import.update_attribute(:finished_at, nil)
      end

      it "returns success" do
        get :index
        response.code.should == "200"
      end

      it "fetches a list of pending imports" do
        get :index
        assigns(:imports).map(&:id).should == [pending_import.id]
      end
    end

    context "when the user is not an admin" do
      let(:user) { users(:the_collaborator) }

      it "returns forbidden" do
        get :index
        response.code.should == "403"
      end
    end
  end
end


