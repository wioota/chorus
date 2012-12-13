require 'minimal_spec_helper'
require 'greenplum_connection'
require_relative '../../spec/support/database_integration/instance_integration'

describe GreenplumConnection::InstanceConnection, :database_integration do
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

  let(:instance) { GreenplumConnection::InstanceConnection.new(details) }

  describe "#initialize" do
    it "sets up the instance parameters" do
      instance.settings.should == details
    end

    it "creates a accessor method for each setting" do
      details.keys.each do |key|
        instance.send(key).should == details[key]
      end
    end
  end

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

  describe "#databases" do
  end

  describe "#schemas" do
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
end
