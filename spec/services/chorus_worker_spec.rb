require 'spec_helper'

describe "ChorusWorker" do
  describe "monkey patch to QC.log" do
    let(:timestamp) { 1.hour.ago }

    it "adds a timestamps to the data" do
      Timecop.freeze(timestamp) do
        mock(Scrolls).log(is_a(Hash)).times(any_times) do |hash|
          hash.should have_key(:timestamp)
        end
        ChorusWorker.new.log(:data => "legit")
      end
    end
  end
end