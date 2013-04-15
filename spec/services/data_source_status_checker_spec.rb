require 'spec_helper'

describe DataSourceStatusChecker do
  shared_examples :it_checks_a_data_source_if_due do |check_method|
    before do
      offline_data_source.state = 'offline'
      [offline_data_source, online_data_source].each do |data_source|
        data_source.last_checked_at = last_checked_at
        data_source.save!
      end
    end

    context 'when the data_source is online or offline' do
      let(:last_checked_at) { nil }

      it 'updates last_online_at' do
        expect {
          DataSourceStatusChecker.check(online_data_source)
        }.to change(online_data_source, :last_online_at)
      end

      it 'updates last_checked_at and last_online_at' do
        expect {
          DataSourceStatusChecker.check(online_data_source)
        }.to change(online_data_source, :last_online_at)
      end
    end
  end

  describe 'checking a hadoop data source:' do
    let(:hdfs_data_source) { FactoryGirl.create :hdfs_data_source, :state => 'offline', :version => '0.20.1' }

    describe '.check_hdfs_data_sources' do
      before do
        stub(hdfs_data_source).version { '1.0.0' }
        DataSourceStatusChecker.check(hdfs_data_source)
      end

      it 'updates the connection status for each data_source' do
        hdfs_data_source.reload.should be_online
      end

      it 'updates the version for each data_source' do
        hdfs_data_source.reload.version.should == '1.0.0'
      end
    end

    it_behaves_like :it_checks_a_data_source_if_due do
      let(:online_data_source) { FactoryGirl.create :hdfs_data_source, :state => 'offline', :version => '0.20.1' }
      let(:offline_data_source) { FactoryGirl.create :hdfs_data_source, :state => 'offline', :version => '0.20.1' }

      before do
        stub(online_data_source).version { '0.20.205' }
        stub(offline_data_source).version { raise StandardError.new('bang') }
      end
    end
  end

  describe 'checking a GPDB data source' do
    let(:data_source_account) { gpdb_data_source.owner_account }
    let(:gpdb_data_source) { FactoryGirl.create :gpdb_data_source, :state => 'offline' }
    let(:connection) { Object.new }

    before do
      stub(gpdb_data_source).connect_as_owner { connection }
    end

    describe '.check' do
      context 'when the database connection is successful' do
        before do
          stub(connection).version { '1.2.3.4' }
        end

        it 'updates the state' do
          DataSourceStatusChecker.check(gpdb_data_source)
          gpdb_data_source.reload.state.should == 'online'
        end

        it 'updates the version' do
          DataSourceStatusChecker.check(gpdb_data_source)
          gpdb_data_source.reload.version.should == '1.2.3.4'
        end
      end

      context 'When connecting to the database fails' do
        before do
          error = GreenplumConnection::DatabaseError.new
          stub(error).error_type { :GENERIC }
          stub(connection).version { raise error }
        end

        it 'does not raise an error' do
          expect {
            DataSourceStatusChecker.check(gpdb_data_source)
          }.not_to raise_error
        end

        it 'sets the state to offline' do
          DataSourceStatusChecker.check(gpdb_data_source)
          gpdb_data_source.state.should == 'offline'
        end
      end
    end

    it_behaves_like :it_checks_a_data_source_if_due do
      let(:online_data_source) { gpdb_data_source }
      let(:offline_data_source) { FactoryGirl.create(:gpdb_data_source) }

      before do
        stub(online_data_source).connect_as_owner {
          connection = Object.new
          stub(connection).version { '1.2.3.4' }
          connection
        }

        stub(offline_data_source).connect_as_owner {
          connection = Object.new

          exception = Exception.new
          wrapped_exception = Object.new
          stub(exception).wrapped_exception { wrapped_exception }

          stub(connection).version { raise GreenplumConnection::DatabaseError.new(exception) }
          connection
        }
      end
    end
  end

  describe 'checking an oracle data source' do
    let(:oracle_data_source) { data_sources(:oracle) }
    let(:connection) { Object.new }

    describe '.check' do
      before do
        stub(oracle_data_source).connect_as_owner { connection }
      end

      context 'when the database connection is successful' do
        before do
          stub(connection).version { '1.0.0' }
        end

        it 'updates the state' do
          DataSourceStatusChecker.check(oracle_data_source)
          oracle_data_source.reload.state.should == 'online'
        end

        it 'updates the version' do
          DataSourceStatusChecker.check(oracle_data_source)
          oracle_data_source.reload.version.should == '1.0.0'
        end
      end

      context 'When connecting to the database fails' do
        before do
          stub(connection).version { raise OracleConnection::DatabaseError.new(Sequel::DatabaseError.new('error message')) }
        end

        it 'does not raise an error' do
          expect {
            DataSourceStatusChecker.check(oracle_data_source)
          }.not_to raise_error
        end

        it 'sets the state to offline' do
          DataSourceStatusChecker.check(oracle_data_source)
          oracle_data_source.state.should == 'offline'
        end
      end
    end

    it_behaves_like :it_checks_a_data_source_if_due do
      let(:online_data_source) { oracle_data_source }
      let(:offline_data_source) { FactoryGirl.create(:oracle_data_source) }
      let(:online_connection) { Object.new }
      let(:offline_connection) { Object.new }

      before do
        stub(online_connection).version { '1.0.0' }
        stub(offline_connection).version { raise OracleConnection::DatabaseError.new(Sequel::DatabaseError.new('error message')) }

        stub(online_data_source).connect_as_owner { online_connection }
        stub(offline_data_source).connect_as_owner { offline_connection }
      end
    end
  end
end

