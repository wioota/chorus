require 'minimal_spec_helper'
require 'greenplum_connection'
require_relative '../../spec/support/database_integration/instance_integration'

describe GreenplumConnection::Base, :database_integration do
  let(:username) { InstanceIntegration::REAL_GPDB_USERNAME }
  let(:password) { InstanceIntegration::REAL_GPDB_PASSWORD }
  let(:database_name) { InstanceIntegration.database_name }
  let(:the_host) { InstanceIntegration.real_gpdb_hostname }
  let(:port) { InstanceIntegration::INSTANCE_CONFIG['port'] }
  let(:db_url) {
    query_params = URI.encode_www_form(:user => details[:username], :password => details[:password], :loginTimeout => 3)
    "jdbc:postgresql://#{details[:host]}:#{details[:port]}/#{details[:database]}?" << query_params
  }

  let(:details) { {
      :host => the_host,
      :username => username,
      :password => password,
      :port => port,
      :database => database_name
  } }

  let(:instance) { GreenplumConnection::Base.new(details) }

  describe "#connect!" do
    before do
      mock.proxy(Sequel).connect(db_url)
    end

    context "successfully" do
      it "with the correct jdbc connection string" do
        instance.connect!
        instance.should be_connected
      end
    end

    context "when the database is unreachable" do
      let(:port) { "976543" }

      it "raises a GreenplumConnection::InstanceUnreachable error" do
        expect {
          instance.connect!
        }.to raise_error(GreenplumConnection::InstanceUnreachable)
      end
    end
  end

  describe "#disconnect" do
    before do
      mock_conn = Object.new
      mock(mock_conn).test_connection { true }

      mock(Sequel).connect(anything) { mock_conn }
      mock(mock_conn).disconnect
      instance.connect!
    end

    it "disconnects Sequel connection" do
      instance.should be_connected
      instance.disconnect
      instance.should_not be_connected
    end
  end

  describe GreenplumConnection::DatabaseConnection do
    describe "#schemas" do
      let(:instance) { GreenplumConnection::DatabaseConnection.new(details) }

      let(:schema_list_sql) do
        <<-SQL
      SELECT
        schemas.nspname as schema_name
      FROM
        pg_namespace schemas
      WHERE
        schemas.nspname NOT LIKE 'pg_%'
        AND schemas.nspname NOT IN ('information_schema', 'gp_toolkit', 'gpperfmon')
      ORDER BY lower(schemas.nspname)
        SQL
      end

      it "returns a list of all the schema names in the connected database" do
        instance.should_not be_connected
        db = Sequel.connect(db_url)
        instance.schemas.should == db.fetch(schema_list_sql).all.collect { |row| row[:schema_name] }
        instance.should_not be_connected
      end
    end
  end

  describe GreenplumConnection::InstanceConnection do
    let(:instance) { GreenplumConnection::InstanceConnection.new(details) }
    let(:database_name) { 'postgres' }

    describe "#databases" do
      let(:database_list_sql) do
        <<-SQL
          SELECT
            datname
          FROM
            pg_database
          WHERE
            datallowconn IS TRUE AND datname NOT IN ('postgres', 'template1')
            ORDER BY lower(datname) ASC
        SQL
      end

      it "returns a list of all the database names in the connected instance" do
        instance.should_not be_connected
        db = Sequel.connect(db_url)
        instance.databases.should == db.fetch(database_list_sql).all.collect { |row| row[:datname] }
        instance.should_not be_connected
      end
    end
  end
end
