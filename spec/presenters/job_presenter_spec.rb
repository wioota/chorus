require 'spec_helper'

describe JobPresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:job) { jobs(:default) }
  let(:options) { {} }
  let(:workspace) { job.workspace }
  let(:presenter) { JobPresenter.new(job, view, options) }

  before(:each) do
    set_current_user(user)
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:workspace)
      hash.should have_key(:name)
      hash.should have_key(:last_run)
      hash.should have_key(:next_run)
      hash.should have_key(:frequency)
      hash.should have_key(:state)
      hash.should have_key(:id)
    end

   end
end
