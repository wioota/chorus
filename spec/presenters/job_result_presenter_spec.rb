require 'spec_helper'

describe JobResultPresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:job) { jobs(:default) }
  let(:job_result) { FactoryGirl.create(:job_result) }
  let(:presenter) { JobResultPresenter.new(job_result, view) }

  describe '#to_hash' do
    let(:hash) { presenter.to_hash }
    let(:keys) { [:succeeded, :started_at, :finished_at] }

    it "includes the right keys" do
      keys.each do |key|
        hash.should have_key(key)
      end
    end
  end
end