require 'spec_helper'

describe JobRunner do

  describe '#run' do
    let(:job1) { FactoryGirl.create(:job) }
    let(:job2) { FactoryGirl.create(:job) }
    let(:job3) { FactoryGirl.create(:job) }

    before do
      stub(Job).ready_to_run { [job1, job2] }
    end

    it 'finds the jobs that are ready to run and runs them' do
      stub(job1).run
      stub(job2).run
      stub(job3).run

      JobRunner.run

      expect(job1).to have_received.run
      expect(job2).to have_received.run
      expect(job3).not_to have_received.run
    end
  end
end