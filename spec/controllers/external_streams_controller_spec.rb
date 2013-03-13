require 'spec_helper'

describe ExternalStreamsController do
  let(:import) { imports(:one)}
  let(:user) { import.user }
  let(:source_table) { import.source_dataset }

  it "returns 401 if there is no stream key" do
    get :show
    response.code.should == "401"
  end

  it "returns 401 if the stream key is bogus" do
    get :show, :stream_key => 'f00baa'
    response.code.should == "401"
  end

  context "with a valid stream_key" do
    let(:connection) {
      object = Object.new
      stub(source_table).connect_as(user) { object }
      object
    }

    let(:streamer_options) do
      {
        :row_limit => 12,
        :target_is_greenplum => true,
        :show_headers => false
      }
    end

    before do
      import.update_attribute(:stream_key, '12345')
      stub(Import).find_by_stream_key('12345') { import }

      streamer = Object.new
      mock(SqlStreamer).new(source_table.all_rows_sql(12), connection, streamer_options) { streamer }
      mock(streamer).enum { "foo" }
    end

    it "initializes the correct dataset streamer and streams without a header row" do
      get :show, :stream_key => '12345', :row_limit => 12
      response.should be_success
      response.body.should == "foo"
    end
  end
end

