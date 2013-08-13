require 'spec_helper'

describe JobResultsController do
  before { log_in users(:owner) }
  let(:job) { jobs(:default) }

  describe '#show' do
    context "when requesting only the latest result" do
      let(:params) { {:job_id => job.id, :id => 'latest'} }

      generate_fixture "jobResult.json" do
        get :show, params
      end
    end
  end
end