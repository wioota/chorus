require 'spec_helper'

describe "ChorusWorker" do
  describe "monkey patch to QC.log" do
    it "adds a timestamps to the data" do
      Timecop.freeze(Time.now) do
        mock(Scrolls).log(hash_including({:timestamp => Time.now.to_s})).times(any_times)
        ChorusWorker.new.log(:data => "legit")
      end
    end
  end
end