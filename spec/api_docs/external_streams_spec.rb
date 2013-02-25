require 'spec_helper'

resource "Internal Use: External Streams" do
  let(:import) { imports(:one) }
  let(:user) { import.user }
  let(:source_table) { import.source_dataset }

  before do
    import.update_attribute(:stream_key, '12345')
  end

  get "/external_stream" do
    parameter :stream_key, "API key for authentication"
    parameter :row_limit, "Maximum number of rows to stream"

    required_parameters :stream_key

    let(:stream_key) { '12345' }
    let(:row_limit) { '12' }

    example_request "Stream data from an existing dataset (to be consumed by a GPDB external table)" do
      status.should == 200
    end
  end
end
