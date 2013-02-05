require 'spec_helper'

describe DatasetStreamer, :greenplum_integration do
  let(:database) { GpdbDatabase.find_by_name_and_data_source_id(InstanceIntegration.database_name, InstanceIntegration.real_gpdb_data_source) }
  let(:dataset) { database.find_dataset_in_schema("base_table1", "test_schema") }
  let(:user) { InstanceIntegration.real_gpdb_account.owner }
  let(:streamer) { DatasetStreamer.new(dataset, user) }
  let(:row_limit) { nil }

  let(:streamed_data) { [
    {:id => 1, :something => 'hello'},
    {:id => 2, :something => 'cruel' },
    {:id => 3, :something => 'world'}
  ] }

  before do
    any_instance_of(GreenplumConnection) do |conn|
      stub(conn).stream_dataset(dataset, nil) do |dataset, row_limit, block|
        streamed_data.each do |row|
          block.call row
        end

        true
      end
    end
  end

  describe "#initialize" do
    it "takes a dataset and user" do
      streamer.user.should == user
      streamer.dataset.should == dataset
    end
  end

  describe "#enum" do
    it "returns an enumerator that yields the header and rows from the dataset in csv" do
      check_enumerator(streamer.enum)
    end

    context "with quotes in the data" do
      let(:streamed_data) {
        [{
          :id => 1, :double_quotes => %Q{with"double"quotes}, :single_quotes => %Q{with'single'quotes}, :comma => %Q{with,comma}
        }]
      }
      let(:dataset) { database.find_dataset_in_schema("stream_table_with_quotes", "test_schema3") }

      it "escapes quotes in the csv" do
        enumerator = streamer.enum
        enumerator.next.split("\n").last.should == %Q{1,"with""double""quotes",with'single'quotes,"with,comma"}
        finish_enumerator(enumerator)
      end
    end

    context "with row_limit" do
      let(:row_limit) { 2 }
      let(:streamer) { DatasetStreamer.new(dataset, user, row_limit) }

      it "uses the limit" do
        enumerator = streamer.enum
        enumerator.next
        finish_enumerator(enumerator)
      end
    end

    context "for connection errors" do
      it "returns the error message" do
        any_instance_of(GpdbSchema) do |schema|
          stub(schema).connect_with(anything) {
            stub(Object.new).stream_dataset.with_any_args {
              raise GreenplumConnection::DatabaseError, StandardError.new("Some friendly error message")
            }
          }
        end

        enumerator = streamer.enum
        enumerator.next.should == "Some friendly error message"
        finish_enumerator enumerator
      end
    end

    context "for a dataset with no rows" do
      let(:dataset) { database.find_dataset_in_schema("stream_empty_table", "test_schema3") }
      let(:streamed_data) { [] }

      it "returns the error message" do
        enumerator = streamer.enum
        enumerator.next.should == "The requested dataset contains no rows"
        finish_enumerator(enumerator)
      end
    end

    def check_enumerator(enumerator)
      next_result = enumerator.next
      header_row, first_result = next_result.split("\n",2)
      header_row.should == "id,something"

      first_result.should == "#{streamed_data[0][:id]},#{streamed_data[0][:something]}\n"
      streamed_data.each_with_index do |row_data, index|
        next if index == 0
        enumerator.next.should == "#{row_data[:id]},#{row_data[:something]}\n"
      end
      finish_enumerator(enumerator)
    end
  end

  def finish_enumerator(enum)
    while true
      enum.next
    end
  rescue
  end
end
