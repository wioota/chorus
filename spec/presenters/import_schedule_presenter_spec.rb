require 'spec_helper'

describe ImportSchedulePresenter, :type => :view do
  before do
    any_instance_of(ImportSchedule) do |d|
      stub(d).table_exists? { false }
    end

    @presenter = ImportSchedulePresenter.new(import_schedule, view, {:dataset_id => dataset_id})

    any_instance_of(Dataset) do |d|
      stub(d).can_import_from(anything) { true }
    end
  end

  let(:import_schedule) do
    schedule = import_schedules(:default)
    schedule.new_table = false
    schedule.destination_dataset_id = 1234
    schedule.save
    schedule
  end

  describe "#to_hash" do
    let(:hash) { @presenter.to_hash }
    let(:dataset_id) { 111 }
    let(:import) { nil }

    it "includes the right keys" do
      hash[:start_datetime].should == import_schedule.start_datetime
      hash[:end_date].should == import_schedule.end_date
      hash[:to_table].should == import_schedule.to_table
      hash[:frequency].should == import_schedule.frequency
      hash[:sample_count].should == import_schedule.sample_count
      hash[:truncate].should == import_schedule.truncate
      hash[:next_import_at].should == import_schedule.next_import_at
      hash[:new_table].should == import_schedule.new_table
      hash[:destination_dataset_id].should == import_schedule.destination_dataset_id
      hash[:dataset_id].should == dataset_id
      hash[:source_id].should == import_schedule.source_dataset_id
    end
  end
end