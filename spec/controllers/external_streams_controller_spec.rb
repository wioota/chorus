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
    before do
      import.update_attribute(:stream_key, '12345')
    end

    it "initializes the correct dataset streamer and streams without a header row" do
      streamer = Object.new
      mock(DatasetStreamer).new(source_table, user, row_limit: '12', target_is_greenplum: true) { streamer }
      mock(streamer).enum(false) { "foo" }  # testing the header row
      get :show, :stream_key => '12345', :row_limit => 12
      response.should be_success
      response.body.should == "foo"
    end
  end
end

