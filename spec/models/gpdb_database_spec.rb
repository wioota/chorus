require 'spec_helper'

describe GpdbDatabase do
  describe "validations" do
    it 'has a valid factory' do
      FactoryGirl.build(:gpdb_database).should be_valid
    end

    it { should validate_presence_of(:name) }

    it 'does not allow strange characters in the name' do
      ['/', '&', '?'].each do |char|
        new_database = FactoryGirl.build(:gpdb_database, :name =>"schema#{char}name")
        new_database.should_not be_valid
        new_database.should have_error_on(:name)
      end
    end

    describe 'name uniqueness' do
      let(:existing) { gpdb_databases(:default) }

      context 'in the same instance' do
        it 'does not allow two databases with the same name' do
          new_database = FactoryGirl.build(:gpdb_database,
                                           :name => existing.name,
                                           :data_source => existing.data_source)
          new_database.should_not be_valid
          new_database.should have_error_on(:name).with_message(:taken)
        end
      end

      context 'in a different instance' do
        it 'allows same names' do
          new_database = FactoryGirl.build(:gpdb_database, :name => existing.name)
          new_database.should be_valid
        end
      end
    end
  end

  describe '#refresh' do
    let(:gpdb_data_source) { FactoryGirl.build_stubbed(:gpdb_data_source) }
    let(:account) { FactoryGirl.build_stubbed(:instance_account, :instance => gpdb_data_source) }
    let(:db_names) { ["db_a", "db_B", "db_C", "db_d"] }
    let(:connection) { Object.new }

    before(:each) do
      stub(gpdb_data_source).connect_with(account) { connection }
      stub(connection).databases { db_names }
    end

    it "creates new copies of the databases in our db" do
      GpdbDatabase.refresh(account)

      databases = gpdb_data_source.databases

      databases.length.should == 4
      databases.map { |db| db.name }.should =~ db_names
      databases.map { |db| db.data_source_id }.uniq.should == [gpdb_data_source.id]
    end

    it "returns a list of GpdbDatabase objects" do
      results = GpdbDatabase.refresh(account)

      db_objects = []
      db_names.each do |name|
        db_objects << gpdb_data_source.databases.find_by_name(name)
      end

      results.should match_array(db_objects)
    end

    it "does not re-create databases that already exist in our database" do
      GpdbDatabase.refresh(account)
      expect { GpdbDatabase.refresh(account) }.not_to change(GpdbDatabase, :count)
    end

    context "when database objects are stale" do
      before do
        GpdbDatabase.all.each { |database|
          database.mark_stale!
        }
      end

      it "marks them as non-stale" do
        GpdbDatabase.refresh(account)
        account.instance.databases.each { |database|
          database.reload.should_not be_stale
        }
      end
    end
  end

  context "refresh using a real greenplum instance", :greenplum_integration do
    let(:account) { GreenplumIntegration.real_account }

    it "sorts the database by name in ASC order" do
      results = GpdbDatabase.refresh(account)
      result_names = results.map { |db| db.name.downcase.gsub(/[^0-9A-Za-z]/, '') }
      result_names.should == result_names.sort
    end
  end

  describe "reindex_dataset_permissions" do
    let(:database) { gpdb_databases(:default) }

    it "calls solr_index on all datasets" do
      database.datasets.each do |dataset|
        mock(Sunspot).index(dataset)
      end
      GpdbDatabase.reindex_dataset_permissions(database.id)
    end

    it "does not call solr_index on stale datasets" do
      dataset = database.datasets.first
      dataset.update_attributes!({:stale_at => Time.current}, :without_protection => true)
      stub(Sunspot).index(anything)
      dont_allow(Sunspot).index(dataset)
      GpdbDatabase.reindex_dataset_permissions(database.id)
    end

    it "does a solr commit" do
      mock(Sunspot).commit
      GpdbDatabase.reindex_dataset_permissions(database.id)
    end

    it "continues if exceptions are raised" do
      database.datasets.each do |dataset|
        mock(Sunspot).index(dataset) { raise "error!" }
      end
      mock(Sunspot).commit
      GpdbDatabase.reindex_dataset_permissions(database.id)
    end
  end

  context "association" do
    it { should have_many :schemas }

    it "has many datasets" do
      gpdb_databases(:default).datasets.should include(datasets(:table))
    end
  end

  describe "callbacks" do
    let(:database) { gpdb_databases(:default) }

    describe "before_save" do
      describe "#mark_schemas_as_stale" do
        it "if the database has become stale, schemas will also be marked as stale" do
          database.update_attributes!({:stale_at => Time.current}, :without_protection => true)
          schema = database.schemas.first
          schema.should be_stale
          schema.stale_at.should be_within(5.seconds).of(Time.current)
        end
      end
    end
  end

  describe ".create_schema" do
    let(:connection) { Object.new }
    let(:database) { gpdb_databases(:default) }
    let(:user) { users(:owner) }
    let(:schema_name) { "stuff" }

    before do
      stub(database).connect_as(user) { connection }
      stub(GpdbSchema).refresh.with_any_args { database.schemas.create(:name => schema_name) }
    end

    it "should create the schema" do
      mock(connection).create_schema(schema_name)
      expect {
        database.create_schema(schema_name, user).name.should == schema_name
      }.to change(GpdbSchema, :count).by(1)
    end

    context "when the schema is invalid" do
      before do
        any_instance_of(GpdbSchema) do |schema|
          stub(schema).valid? { false }
        end
      end

      it "should not create the database" do
        dont_allow(connection).create_schema.with_any_args
        expect do
          expect do
            database.create_schema(schema_name, user)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end.not_to change(GpdbSchema, :count)
      end
    end
  end

  describe "#connect_with" do
    let(:database) { gpdb_databases(:default) }
    let(:instance) { database.data_source }
    let(:account) { instance_accounts(:unauthorized) }

    it "should return a GreenplumConnection" do
      mock(GreenplumConnection).new({
                                                            :host => instance.host,
                                                            :port => instance.port,
                                                            :username => account.db_username,
                                                            :password => account.db_password,
                                                            :database => database.name,
                                                            :logger => Rails.logger
      }) { "this is my connection" }
      database.connect_with(account).should == "this is my connection"
    end
  end

  describe "#destroy" do
    let(:database) { gpdb_databases(:default) }

    it "should not delete the database entry" do
      database.destroy
      expect {
        database.reload
      }.to_not raise_error(Exception)
    end

    it "should update the deleted_at field" do
      database.destroy
      database.reload.deleted_at.should_not be_nil
    end

    it "destroys dependent schemas" do
      schemas = database.schemas
      schemas.length.should > 0

      database.destroy
      schemas.each do |schema|
        GpdbSchema.find_by_id(schema.id).should be_nil
      end
    end

    it "does not destroy instance accounts (but secretly deletes the join model)" do
      database.instance_accounts << database.data_source.accounts.first
      instance_accounts = database.reload.instance_accounts

      instance_accounts.length.should > 0

      database.destroy
      instance_accounts.each do |account|
        InstanceAccount.find_by_id(account.id).should_not be_nil
      end
    end
  end
end
