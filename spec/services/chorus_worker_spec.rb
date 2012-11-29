require 'spec_helper'

describe ChorusWorker do
  let(:worker) { ChorusWorker.new }

  describe "#timestamped_log" do
    it "adds a timestamps to the data" do
      Timecop.freeze(Time.now) do
        mock(worker).log({ :data => "legit", :timestamp => Time.now.to_s })
        worker.timestamped_log(:data => "legit")
      end
    end
  end
end