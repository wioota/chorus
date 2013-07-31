require 'spec_helper'

describe ImportSourceDataTaskPresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:job_task) { job_tasks(:job_task_isdt) }
  let(:presenter) { ImportSourceDataTaskPresenter.new(job_task, view) }

  before(:each) do
    set_current_user(user)
  end

  describe '#to_hash' do
    let(:hash) { presenter.to_hash }
    let(:keys) { [:id, :workspace, :job, :action, :index, :name, "source_id", "destination_id", "destination_name", "row_limit", "truncate"] }

    it "includes the right keys" do
      keys.each do |key|
        hash.should have_key(key)
      end
    end
  end
end