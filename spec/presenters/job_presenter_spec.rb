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
    let(:keys) { [:workspace, :name, :last_run, :next_run, :interval_unit, :interval_value, :state, :id] }

    describe "list_view" do
      let(:options) { {list_view: true} }
      let(:hash) { presenter.to_hash }
      
      it "includes the right keys" do
        keys.each do |key|
          hash.should have_key(key)
        end
        hash.should_not have_key(:tasks)
      end
    end

    context "not list_view" do
      let(:hash) { presenter.to_hash }
      it "includes the right keys" do
        (keys + [:tasks]).each do |key|
          hash.should have_key(key)
        end
      end
    end
   end
end
