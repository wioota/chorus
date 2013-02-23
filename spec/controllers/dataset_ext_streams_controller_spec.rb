require 'spec_helper'

describe DatasetExtStreamsController do
  let(:import) { imports(:one)}
  let(:user) { import.user }
  let(:source_table) { import.source_dataset }

  it "returns 401 if there is no stream key" do
    get :show, :dataset_id => source_table.to_param
    response.code.should == "401"
  end

  it "returns 401 if the stream key is bogus" do
    get :show, :dataset_id => source_table.to_param, :stream_key => 'f00baa'
    response.code.should == "401"
  end

  context "with a valid stream_key" do
    before do
      import.update_attribute(:stream_key, '12345')
    end

    it "initializes the correct dataset streamer" do
      mock.proxy(DatasetStreamer).new(source_table, user, '12')
      get :show, :dataset_id => source_table.to_param, :stream_key => '12345', :row_limit => 12
      response.should be_success
    end
  end
end

