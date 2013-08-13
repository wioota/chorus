require 'spec_helper'

describe JobTaskResult do
  describe "validations" do
    it { should ensure_inclusion_of(:status).in_array(JobTaskResult::VALID_STATUSES) }
  end

  describe "#finish" do
    let(:result) { JobTaskResult.new }

    it "sets finished_at to now" do
      Timecop.freeze {
        result.finish(JobTaskResult::SUCCESS)
        result.finished_at.should == Time.current
      }
    end

    it "sets the status" do
      result.finish(JobTaskResult::SUCCESS)
      result.status.should == JobTaskResult::SUCCESS
    end

    it "returns the JobTaskResult" do
      result.finish(JobTaskResult::SUCCESS).should == result
    end
  end
end

