require 'spec_helper'

describe AlpineWorkfilePresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles(:'alpine_flow') }
  let(:options) { {} }
  let(:presenter) { AlpineWorkfilePresenter.new(workfile, view, options) }

  before(:each) do
    set_current_user(user)
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    describe "when the 'workfile_as_latest_version' option is set" do
      let(:options) { {:workfile_as_latest_version => true} }

      it "creates a version_info hash that includes the created and updated time of the workfile" do
        hash[:version_info].should == {:created_at => workfile.created_at, :updated_at => workfile.updated_at}
      end
    end

    it "presents execution database" do
      workfile.execution_location = gpdb_databases(:alternate)
      workfile.execution_location.should be_a(GpdbDatabase)
      hash[:execution_location].should == Presenter.present(workfile.execution_location, view, :succinct => true)
    end

    context "when presenting for a list_view" do
      let(:options) { {:list_view => true} }
      let(:workfile) { workfiles("alpine_flow") }

      it "does not show the execution location, because that becomes an N+1 query and we don't need the data" do
        hash.should_not have_key(:execution_location)
      end
    end
  end
end
