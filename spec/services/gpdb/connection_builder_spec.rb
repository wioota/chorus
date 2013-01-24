require 'spec_helper'

describe Gpdb::ConnectionBuilder do
  let(:gpdb_data_source) { FactoryGirl::create :gpdb_data_source, :host => "hello" }
  let(:instance_account) { gpdb_data_source.owner_account }
  let(:fake_connection_adapter) { stub(Object.new).disconnect!.subject }
  let(:connection_timeout) { Gpdb.gpdb_login_timeout }

  let(:expected_connection_params) do
    {
      host: gpdb_data_source.host,
      port: gpdb_data_source.port,
      database: expected_database,
      username: instance_account.db_username,
      password: instance_account.db_password,
      adapter: "jdbcpostgresql",
      pg_params: "?loginTimeout=#{connection_timeout}"
    }
  end

  let(:expected_database) { gpdb_data_source.db_name }

  describe ".connect!" do
    before do
      stub(ActiveRecord::Base).postgresql_connection(expected_connection_params) { fake_connection_adapter }
    end

    context "when connection is successful" do
      context "when a database name is passed" do
        let(:expected_database) { "john_the_database" }

        it "connections to the given database and instance, with the given account" do
          Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account, "john_the_database")
        end
      end

      context "when no database name is passed" do
        it "connects to the given instance's 'db_name'" do
          Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account)
        end
      end

      it "calls the given block with the postgres connection" do
        mock(fake_connection_adapter).query("foo")
        Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account) do |conn|
          conn.query("foo")
        end
      end

      it "returns the result of the block" do
        result = Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account) do |conn|
          "value returned by block"
        end
        result.should == "value returned by block"
      end

      it "disconnects afterward" do
        mock(fake_connection_adapter).disconnect!
        Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account)
      end
    end

    context "when the connection fails" do
      let(:adapter_exception) { ActiveRecord::JDBCError.new }
      let(:fake_connection_adapter) { raise adapter_exception }
      let(:raised_message) { "#{Time.current.strftime("%Y-%m-%d %H:%M:%S")} ERROR: Failed to establish JDBC connection to #{gpdb_data_source.host}:#{gpdb_data_source.port}" }

      context "when the instance is overloaded" do
        let(:adapter_exception) { ActiveRecord::JDBCError.new("FATAL: sorry, too many clients already") }

        it 'raises a Gpdb::InstanceOverloaded error' do
          expect {
            Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account)
          }.to raise_error(Gpdb::InstanceOverloaded)
        end
      end

      context "when the instance is down" do
        context "and times out" do
          let(:adapter_exception) { ActiveRecord::JDBCError.new("Connection attempt timed out") }

          it 'raises a Gpdb::InstanceUnreachable error' do
            expect {
              Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account)
            }.to raise_error(Gpdb::InstanceUnreachable)
          end
        end

        context "and fails to connect" do
          let(:adapter_exception) { ActiveRecord::JDBCError.new("The connection attempt failed") }

          it 'raises a Gpdb::InstanceUnreachable error' do
            expect {
              Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account)
            }.to raise_error(Gpdb::InstanceUnreachable)
          end
        end
      end

      context "with an invalid password" do
        let(:adapter_exception) { ActiveRecord::JDBCError.new("org.postgresql.util.PSQLException: FATAL: password authentication failed for user '#{instance_account.db_username}'") }
        let(:nice_exception) { ActiveRecord::JDBCError.new("Password authentication failed for user '#{instance_account.db_username}'") }
        let(:raised_message) { "#{Time.current.strftime("%Y-%m-%d %H:%M:%S")} ERROR: Failed to establish JDBC connection to #{gpdb_data_source.host}:#{gpdb_data_source.port}" }

        it "raises an InvalidLogin exception" do
          Timecop.freeze(Time.current)
          mock(Rails.logger).error("#{raised_message} - #{adapter_exception.message}")
          expect {
            Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account)
          }.to raise_error(ActiveRecord::JDBCError, nice_exception.message)
          Timecop.return
        end
      end
    end

    context "when the sql command fails" do
      let(:adapter_exception) { ActiveRecord::StatementInvalid.new }
      let(:log_message) { "#{Time.current.strftime("%Y-%m-%d %H:%M:%S")} ERROR: SQL Statement Invalid" }
      let(:sql_command) { "SELECT * FROM BOGUS_TABLE;" }

      it "does not catch the error" do
        Timecop.freeze(Time.current)
        mock(Rails.logger).warn("#{log_message} - #{adapter_exception.message}")
        mock(fake_connection_adapter).query.with_any_args { raise ActiveRecord::StatementInvalid }
        expect {
          Gpdb::ConnectionBuilder.connect!(gpdb_data_source, instance_account) do |conn|
            conn.query sql_command
          end
        }.to raise_error(ActiveRecord::StatementInvalid, adapter_exception.message)
        Timecop.return
      end
    end
  end
end
