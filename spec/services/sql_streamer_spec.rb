require 'spec_helper'

describe SqlStreamer do
  let(:schema) { schemas(:public) }
  let(:sql) { "select 1;" }
  let(:user) { users(:owner) }
  let(:row_limit) { nil }
  let(:options) { row_limit ? {row_limit: row_limit} : {} }
  let(:streamer) { SqlStreamer.new(schema, sql, user, options) }

  let(:streamed_data) { [
      {:id => 1, :something => 'hello'},
      {:id => 2, :something => 'cruel' },
      {:id => 3, :something => 'world'}
  ] }

  before do
    any_instance_of(GreenplumConnection) do |conn|
      stub(conn).stream_sql(sql, row_limit) do |sql, row_limit, block|
        streamed_data.each do |row|
          block.call row
        end
        true
      end
    end
  end

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

    it "should not yield the header row when told not to" do
      check_enumerator(streamer.enum(false), false)
    end

    context "with special characters in the data" do
      let(:streamed_data) {
        [{
             :id => 1,
             :double_quotes => %Q{with"double"quotes},
             :single_quotes => %Q{with'single'quotes},
             :comma => 'with,comma'
         }]
      }

      it "escapes the characters in the csv" do
        enumerator = streamer.enum
        enumerator.next.split("\n").last.should == %Q{1,"with""double""quotes",with'single'quotes,"with,comma"}
        finish_enumerator(enumerator)
      end

      describe "when the sql streamer has greenplum as target" do
        let(:streamer) { SqlStreamer.new(schema, sql, user, {target_is_greenplum: true}) }

        let(:streamed_data) do
          [{
             :id => 1,
             :newline => '\n',
             :carriage_return => '\r',
             :null => '\0'
           }]
        end

        it "converts special characters to whitespace or empty string" do
          enumerator = streamer.enum
          enumerator.next.split("\n").last.should == '1, , ,""'
          finish_enumerator(enumerator)
        end
      end
    end

    context "with row_limit" do
      let(:row_limit) { 2 }

      it "uses the limit" do
        enumerator = streamer.enum
        enumerator.next
        finish_enumerator(enumerator)
      end
    end

    context "with a string row_limit" do
      let(:row_limit) { 2 }

      it "sends the limit as an integer" do
        enumerator = SqlStreamer.new(schema, sql, user, row_limit: "2").enum
        enumerator.next
        finish_enumerator(enumerator)
      end
    end

    context "for connection errors" do
      it "returns the error message" do
        any_instance_of(GpdbSchema) do |schema|
          stub(schema).connect_with(anything) {
            stub(Object.new).stream_sql.with_any_args {
              raise GreenplumConnection::DatabaseError, StandardError.new("Some friendly error message")
            }
          }
        end

        enumerator = streamer.enum
        enumerator.next.should == "Some friendly error message"
        finish_enumerator enumerator
      end
    end

    context "for results with no rows" do
      let(:streamed_data) { [] }

      it "returns the error message" do
        enumerator = streamer.enum
        enumerator.next.should == "The query returned no rows"
        finish_enumerator(enumerator)
      end
    end

    def check_enumerator(enumerator, show_headers=true)
      next_result = enumerator.next
      header_row, first_result = next_result.split("\n",2)
      if show_headers
        header_row.should == "id,something"
      else
        header_row.should_not == "id,something"
        first_result = header_row
      end

      first_result.should == "#{streamed_data[0][:id]},#{streamed_data[0][:something]}#{show_headers ? "\n" : ""}"
      streamed_data.each_with_index do |row_data, index|
        next if index == 0
        enumerator.next.should == "#{row_data[:id]},#{row_data[:something]}\n"
      end
      finish_enumerator(enumerator)
    end

    def finish_enumerator(enum)
      while true
        enum.next
      end
    rescue
    end
  end
end