shared_examples_for :data_source_integration do
  describe "#valid_db_credentials?" do
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

shared_examples_for :data_source_with_access_control do
  describe "access control" do
    let(:user) { users(:owner) }

    before do
      factory = described_class.name.underscore.to_sym

      @data_source_owned = FactoryGirl.create factory, :owner => user
      @data_source_shared = FactoryGirl.create factory, :shared => true
      @data_source_with_membership = FactoryGirl.create factory
      @data_source_forbidden = FactoryGirl.create factory

      @membership_account = FactoryGirl.build :instance_account, :owner => user, :instance => @data_source_with_membership
      @membership_account.save(:validate => false)
    end

    describe '.accessible_to' do
      it "returns owned instances" do
        described_class.accessible_to(user).should include @data_source_owned
      end

      it "returns shared instances" do
        described_class.accessible_to(user).should include @data_source_shared
      end

      it "returns data source instances to which user has membership" do
        described_class.accessible_to(user).should include @data_source_with_membership
      end

      it "does not return instances the user has no access to" do
        described_class.accessible_to(user).should_not include(@data_source_forbidden)
      end
    end

    describe '#accessible_to' do
      it 'returns true if the instance is shared' do
        @data_source_shared.accessible_to(user).should be_true
      end

      it 'returns true if the instance is owned by the user' do
        @data_source_owned.accessible_to(user).should be_true
      end

      it 'returns true if the user has an instance account' do
        @data_source_with_membership.accessible_to(user).should be_true
      end

      it 'returns false otherwise' do
        @data_source_forbidden.accessible_to(user).should be_false
      end
    end
  end

  describe ".unshared" do
    it "returns unshared gpdb instances" do
      unshared_data_sources = described_class.unshared
      unshared_data_sources.length.should > 0
      unshared_data_sources.each { |i| i.should_not be_shared }
    end
  end
end