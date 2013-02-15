require 'spec_helper'

describe SqlStreamer, :database_integration do
  let(:database) { GpdbDatabase.find_by_name_and_gpdb_instance_id(InstanceIntegration.database_name, InstanceIntegration.real_gpdb_instance) }
  let(:dataset) { database.find_dataset_in_schema("base_table1", "test_schema") }
  let(:schema) { dataset.schema }
  let(:sql) { dataset.all_rows_sql }
  let(:user) { InstanceIntegration.real_gpdb_account.owner }
  let(:row_limit) { nil }
  let(:streamer) { SqlStreamer.new(schema, sql, user, row_limit) }

  describe "#initialize" do
    it "takes a sql fragment and user" do
      streamer.user.should == user
      streamer.sql.should == sql
    end
  end

  describe "#enum" do
    it "returns an enumerator that yields the header and rows from the sql in csv" do
      check_enumerator(streamer.enum)
    end

    context "with quotes in the data" do
      let(:sql) do
        <<-SQL
          SELECT 1 as c1, 'with"double"quotes' as c2, 'with''single''quotes' as c3, 'with,comma' as c4;
        SQL
      end

      it "escapes quotes in the csv" do
        enumerator = streamer.enum
        enumerator.next.split("\n").last.should == %Q{1,"with""double""quotes",with'single'quotes,"with,comma"}
        finish_enumerator(enumerator)
      end
    end

    context "for connection errors" do
      it "returns the error message" do
        any_instance_of(GpdbSchema) do |schema|
          stub(schema).with_gpdb_connection(anything) {
            raise ActiveRecord::JDBCError, "Some friendly error message"
          }
        end

        enumerator = streamer.enum
        enumerator.next.should == "Some friendly error message"
        finish_enumerator enumerator
      end
    end

    context "for results with no rows" do
      let(:dataset) { database.find_dataset_in_schema("stream_empty_table", "test_schema3") }

      it "returns the error message" do
        enumerator = streamer.enum
        enumerator.next.should == "The query returned no rows"
        finish_enumerator(enumerator)
      end
    end

    context "with a string limit" do
      let(:row_limit) { '3' }

      it "limits the number of records returned" do
        enumerator = streamer.enum

        expect {
          row_limit.to_i.times do
            enumerator.next
          end
        }.to_not raise_error(StopIteration)

        expect {
          enumerator.next
        }.to raise_error(StopIteration)
      end
    end

    context "with a nonsense limit" do
      let(:row_limit) { 'undefined' }

      it "does not limit" do
        check_enumerator(streamer.enum)
      end
    end

    context "testing checking in connections" do
      it "does not leak connections" do
        conn_size = ActiveRecord::Base.connection_pool.send(:active_connections).size
        enum = streamer.enum
        finish_enumerator(enum)
        ActiveRecord::Base.connection_pool.send(:active_connections).size.should == conn_size
      end
    end

    let(:table_data) { ["0,0,0,apple,2012-03-01 00:00:02\n",
                        "1,1,1,apple,2012-03-02 00:00:02\n",
                        "2,0,2,orange,2012-04-01 00:00:02\n",
                        "3,1,3,orange,2012-03-05 00:00:02\n",
                        "4,1,4,orange,2012-03-04 00:02:02\n",
                        "5,0,5,papaya,2012-05-01 00:02:02\n",
                        "6,1,6,papaya,2012-04-08 00:10:02\n",
                        "7,1,7,papaya,2012-05-11 00:10:02\n",
                        "8,1,8,papaya,2012-04-09 00:00:02\n"] }

    def check_enumerator(enumerator)
      next_result = enumerator.next
      header_row = next_result.split("\n").first
      header_row.should == "id,column1,column2,category,time_value"

      first_result = next_result.split("\n").last+"\n"
      table_data.delete(first_result).should_not be_nil
      8.times do
        table_data.delete(enumerator.next).should_not be_nil
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
