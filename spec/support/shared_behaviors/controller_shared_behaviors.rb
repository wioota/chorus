shared_examples_for "an action that requires authentication" do |method, action, params = {}|
  describe "when not authenticated" do
    before(:each) do
      log_out
    end

    it "returns unauthorized" do
      send(method, action, params)
      response.code.should == "401"
    end
  end
end

shared_examples_for "a paginated list" do
  let(:params) {{}}

  it "returns a paginated list" do
    send(:get, :index, params)
    response.code.should == '200'
    response.decoded_body.should have_key 'pagination'
    decoded_pagination.page.should == 1
  end
end

shared_examples_for :succinct_list do
  let(:params) { {:succinct => 'true'} }

  it "should present succinctly" do
    mock(Presenter).present(anything, anything, hash_including(:succinct => true))
    send(:get, :index, params)
  end
end

shared_examples_for "prefixed file downloads" do
  context "when file_download.name_prefix config option is set" do
    let(:prefix) { "123456789012345678901" }
    before do
      stub(ChorusConfig.instance).[]('file_download.name_prefix') { prefix }
      stub.proxy(ChorusConfig.instance).[](anything)
    end

    it "prefixes the filename correctly" do
      do_request
      response.headers["Content-Disposition"].should == "attachment; filename=\"#{prefix[0..19]}#{expected_filename}\""
    end
  end

  context "when file_download.name_prefix is not set" do
    before do
      stub(ChorusConfig.instance).[]('file_download.name_prefix') { '' }
      stub.proxy(ChorusConfig.instance).[](anything)
    end

    it "does not prefix the filename" do
      do_request
      response.headers["Content-Disposition"].should == "attachment; filename=\"#{expected_filename}\""
    end
  end
end