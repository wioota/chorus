require 'spec_helper'

describe JobBoss do
  describe '#run' do
    let!(:job1) { FactoryGirl.create(:job) }
    let!(:job2) { FactoryGirl.create(:job) }
    let!(:job3) { FactoryGirl.create(:job) }

    before { stub(Job).ready_to_run { [job1, job2] } }

    it 'finds the jobs that are ready to run and runs them' do
      mock(job1).enqueue
      mock(job2).enqueue
      dont_allow(job3).enqueue

      JobBoss.run
    end
  end
end