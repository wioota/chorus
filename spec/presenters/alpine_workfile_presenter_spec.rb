require 'spec_helper'

describe AlpineWorkfilePresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles(:'alpine.afm') }
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
  end
end
