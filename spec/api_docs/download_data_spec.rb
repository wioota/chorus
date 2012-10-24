require 'spec_helper'

resource "Utilities" do
  let(:user) { users(:admin) }

  before do
    log_in user
  end

  post "/download_data" do
    parameter :content, "Contents of the file you wish to download"
    parameter :filename, "Name of the file to download"
    parameter :mime_type, "Mime type of the download"

    required_parameters :content, :filename, :mime_type

    let(:content) { "col1,col2\nrow1,row2" }
    let(:filename) { "downloaded.csv" }
    let(:mime_type) { "text/csv" }

    example_request "Download posted data" do
      explanation <<-DESC
        The posted data is immediately returned as a download with the
        filename and mime_type provided.  Meant to be used to instantiate
        downloads from javascript
      DESC

      status.should == 200
    end
  end
end
