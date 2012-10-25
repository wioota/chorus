require 'spec_helper'

describe ImportSchedulePresenter, :type => :view do
  before do
    @presenter = ImportSchedulePresenter.new(import_schedule, view, {:dataset_id => dataset_id, :import => import})
  end
  let(:import_schedule) { import_schedules(:default) }

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
      hash[:last_scheduled_at].should == import_schedule.last_scheduled_at
      hash[:next_import_at].should == import_schedule.next_import_at
      hash[:new_table].should == import_schedule.new_table
      hash[:destination_dataset_id].should == import_schedule.target_dataset_id
      hash[:is_active].should == import_schedule.is_active
      hash[:dataset_id].should == dataset_id
    end

    context "when given an import" do
      let(:import) { imports(:now) }

      it "should have the import" do
        hash[:execution_info][:started_stamp].should == import.created_at.to_s
      end
    end

    context "when deleted" do
      before do
        stub(import_schedule).is_active { false }
      end

      it "does not include an id" do
        hash[:id].should be_nil
      end
    end
  end
end