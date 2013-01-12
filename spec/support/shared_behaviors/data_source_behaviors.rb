shared_examples_for "DataSource" do
  describe "#valid_db_credentials?", :database_integration do
    it "returns true when the credentials are valid" do
      instance.valid_db_credentials?(account).should be_true
    end

    it "returns true when the credentials are invalid" do
      account.db_username = 'awesome_hat'
      instance.valid_db_credentials?(account).should be_false
    end

    it "raises a DataSourceConnection::Error when other errors occur" do
      instance.host = 'something_fake'
      expect {
        instance.valid_db_credentials?(account)
      }.to raise_error(DataSourceConnection::Error)
    end
  end
end