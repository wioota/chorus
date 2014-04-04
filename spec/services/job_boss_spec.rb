require 'spec_helper'

describe JobBoss do
  describe '#run' do
    let!(:job1) { FactoryGirl.create(:job) }
    let!(:job2) { FactoryGirl.create(:job) }
    let!(:job3) { FactoryGirl.create(:job) }

    before do
      stub(Job).ready_to_run { [job1, job2] }
      stub(Job).awaiting_stop { [job2, job3] }
    end

    it 'finds the jobs that are ready to run and runs them' do
      mock(job1).enqueue
      mock(job2).enqueue
      dont_allow(job3).enqueue

      JobBoss.run
    end

    it 'finds the jobs that have stalled while stopping and idles them' do
      dont_allow(job1).idle
      mock(job2).idle
      mock(job3).idle

      JobBoss.run
    end
  end
end