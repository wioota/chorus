require 'spec_helper'

describe InstanceStatusChecker do
  shared_examples :it_checks_a_data_source_with_exponential_backoff do |check_method|

    define_method :check_and_reload do |data_source|
      begin
        InstanceStatusChecker.check(data_source)
      rescue
        # failed JDBC connections generate exceptions that should probably be handled by specific data_source checkers
      ensure
        data_source.reload
      end
    end

    before do
      [offline_data_source, online_data_source].each do |data_source|
        data_source.last_online_at = last_online_at
        data_source.last_checked_at = last_checked_at
        data_source.save!
      end
    end

    context "when the data_source will be online for the first time" do
      let(:last_online_at) { nil }
      let(:last_checked_at) { nil }
      it "updates the last_online_at timestamp" do
        expect {
          check_and_reload(online_data_source)
        }.to change(online_data_source, :last_online_at)
      end
    end

    context "when data_source is still online" do
      let(:last_online_at) { 1.minute.ago }
      let(:last_checked_at) { 1.minute.ago }

      it "updates the last_checked_at timestamp on data_source" do
        previously_updated_at = online_data_source.updated_at
        expect {
          check_and_reload(online_data_source)
        }.to change(online_data_source, :last_checked_at)
        online_data_source.last_checked_at.should > previously_updated_at
      end

      it "updates last_checked_at and last_online_at" do
        expect {
          check_and_reload(online_data_source)
        }.to change(online_data_source, :last_online_at)
      end
    end

    context "when the data_source becomes offline" do
      let(:last_online_at) { 1.minute.ago }
      let(:last_checked_at) { 1.minute.ago }

      it "doesn't update the last_online_at timestamp for data_sources that are offline" do
        expect {
          check_and_reload(offline_data_source)
        }.not_to change(offline_data_source, :last_online_at)
      end
    end

    context "when the data_source was offline at the last check" do
      context "when elapsed time since last check is greater than maximum check interval" do
        let(:last_online_at) { 1.year.ago }
        let(:last_checked_at) { 1.day.ago }

        it "checks the data_source" do
          expect {
            check_and_reload(offline_data_source)
          }.to change(offline_data_source, :last_checked_at)
        end
      end

      context "when elapsed time since last check is more than double the downtime" do
        let(:last_online_at) { 10.minutes.ago }
        let(:last_checked_at) { 3.minutes.ago }

        it "does not check data_source" do
          expect {
            check_and_reload(offline_data_source)
          }.not_to change(offline_data_source, :last_checked_at)
        end
      end

      context "when elapsed time since last check is less than double the downtime" do
        let(:last_online_at) { 10.minutes.ago }
        let(:last_checked_at) { 7.minutes.ago }

        it "checks the data_source" do
          expect {
            check_and_reload(offline_data_source)
          }.to change(offline_data_source, :last_checked_at)
        end
      end
    end
  end

  describe "Hadoop Instances:" do
    let(:hadoop_instance1) { FactoryGirl.create :hadoop_instance, :state => 'offline', :version => "0.20.1" }

    describe ".check_hdfs_data_sources" do
      let(:hadoop_instance) { FactoryGirl.create(:hadoop_instance) }

      before do
        stub(Hdfs::QueryService).data_source_version(hadoop_instance1) { "1.0.0" }
        InstanceStatusChecker.check(hadoop_instance1)
      end

      it "updates the connection status for each data_source" do
        hadoop_instance1.reload.should be_online
      end

      it "updates the version for each data_source" do
        hadoop_instance1.reload.version.should == "1.0.0"
      end
    end

    it_behaves_like :it_checks_a_data_source_with_exponential_backoff do
      let(:online_data_source) { FactoryGirl.create :hadoop_instance, :state => 'offline', :version => "0.20.1" }
      let(:offline_data_source) { FactoryGirl.create :hadoop_instance, :state => 'offline', :version => "0.20.1" }

      before do
        stub(Hdfs::QueryService).data_source_version(online_data_source) { "0.20.205" }
        stub(Hdfs::QueryService).data_source_version(offline_data_source) { raise StandardError.new('bang') }
      end
    end
  end

  describe "GPDB Instances" do
    let(:data_source_account) { gpdb_data_source.owner_account }
    let(:gpdb_data_source) { FactoryGirl.create :gpdb_data_source, :state => 'offline' }

    describe ".check" do
      context "when the database connection is successful" do
        before do
          stub_gpdb(data_source_account,
                    "select version()" => [{"version" => "PostgreSQL 9.2.15 (Greenplum Database 4.1.1.1 build 1) on i386-apple-darwin9.8.0, compiled by GCC gcc (GCC) 4.4.2 compiled on May 12 2011 18:08:53"}]
          )
        end

        it "updates the state" do
          InstanceStatusChecker.check(gpdb_data_source)
          gpdb_data_source.reload.state.should == "online"
        end

        it "updates the version" do
          InstanceStatusChecker.check(gpdb_data_source)
          gpdb_data_source.reload.version.should == "4.1.1.1"
        end
      end

      context "When retrieving the version fails" do
        before do
          stub_gpdb(data_source_account,
                    "select version()" => [{"version" => ""}]
          )
        end

        it "marks the data_source version as error" do
          InstanceStatusChecker.check gpdb_data_source
          gpdb_data_source.reload.version.should == "Error"
        end
      end

      context "When connecting to the database fails" do
        before do
          stub_gpdb_fail(gpdb_data_source)
        end

        it "does not raise an error" do
          expect {
            InstanceStatusChecker.check(gpdb_data_source)
          }.not_to raise_error
        end

        it "should set the state to 'offline'" do
          InstanceStatusChecker.check(gpdb_data_source)
          gpdb_data_source.state.should == 'offline'
        end
      end
    end

    it_behaves_like :it_checks_a_data_source_with_exponential_backoff do
      let(:online_data_source) { gpdb_data_source }
      let(:offline_data_source) { FactoryGirl.create(:gpdb_data_source) }

      before do
        stub_gpdb(data_source_account,
                  "select version()" => [{"version" => "PostgreSQL 9.2.15 (Greenplum Database 4.1.1.1 build 1) on i386-apple-darwin9.8.0, compiled by GCC gcc (GCC) 4.4.2 compiled on May 12 2011 18:08:53"}]
        )
        stub_gpdb_fail(offline_data_source)
      end
    end
  end

  describe "Oracle Instances" do
    let(:oracle_data_source) { data_sources(:oracle) }
    let(:connection) { Object.new }

    describe ".check" do
      before do
        stub(oracle_data_source).connect_with(oracle_data_source.owner_account) { connection }
      end

      context "when the database connection is successful" do
        before do
          stub(connection).version { '1.0.0' }
        end

        it "updates the state" do
          InstanceStatusChecker.check(oracle_data_source)
          oracle_data_source.reload.state.should == "online"
        end

        it "updates the version" do
          InstanceStatusChecker.check(oracle_data_source)
          oracle_data_source.reload.version.should == "1.0.0"
        end
      end

      context "When connecting to the database fails" do
        before do
          stub(connection).version { raise OracleConnection::DatabaseError.new(Sequel::DatabaseError.new('error message')) }
        end

        it "does not raise an error" do
          expect {
            InstanceStatusChecker.check(oracle_data_source)
          }.not_to raise_error
        end

        it "should set the state to 'offline'" do
          InstanceStatusChecker.check(oracle_data_source)
          oracle_data_source.state.should == 'offline'
        end
      end
    end

    it_behaves_like :it_checks_a_data_source_with_exponential_backoff do
      let(:online_data_source) { oracle_data_source }
      let(:offline_data_source) { FactoryGirl.create(:oracle_data_source) }
      let(:online_connection ) { Object.new }
      let(:offline_connection ) { Object.new }

      before do
        stub(online_connection).version { '1.0.0' }
        stub(offline_connection).version { raise OracleConnection::DatabaseError.new(Sequel::DatabaseError.new('error message')) }

        stub(online_data_source).connect_with(online_data_source.owner_account) { online_connection }
        stub(offline_data_source).connect_with(offline_data_source.owner_account) { offline_connection }
      end
    end
  end
end

