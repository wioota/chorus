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
    query_params = URI.encode_www_form(:user => details[:username], :password => details[:password], :loginTimeout => GreenplumConnection.gpdb_login_timeout)
    "jdbc:postgresql://#{details[:host]}:#{details[:port]}/#{details[:database]}?" << query_params
  }

  before :all do
    InstanceIntegration.setup_gpdb
  end

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
    let(:instance) { GreenplumConnection::DatabaseConnection.new(details) }
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
        db.disconnect
      end
    end

    describe "#create_schema" do
      let(:new_schema_name) { "foobarbaz" }

      after do
        db = Sequel.connect(db_url)
        db.drop_schema(new_schema_name, :if_exists => true)
        db.disconnect
      end

      it "should adds a schema" do
        expect {
          instance.create_schema("foobarbaz")
        }.to change { instance.schemas }
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
        db.disconnect
      end
    end
  end

  describe GreenplumConnection::SchemaConnection do
    let(:instance) { GreenplumConnection::SchemaConnection.new(details.merge(:schema => schema_name)) }
    let(:schema_name) { "test_schema" }

    describe "#functions" do
      let(:schema_functions_sql) do
        <<-SQL
          SELECT t1.oid, t1.proname, t1.lanname, t1.rettype, t1.proargnames, (SELECT t2.typname ORDER BY inputtypeid) AS argtypes, t1.prosrc, d.description
            FROM ( SELECT p.oid,p.proname,
               CASE WHEN p.proargtypes='' THEN NULL
                   ELSE unnest(p.proargtypes)
                   END as inputtype,
               now() AS inputtypeid, p.proargnames, p.prosrc, l.lanname, t.typname AS rettype
             FROM pg_proc p, pg_namespace n, pg_type t, pg_language l
             WHERE p.pronamespace=n.oid
               AND p.prolang=l.oid
               AND p.prorettype = t.oid
               AND n.nspname= '#{schema_name}') AS t1
          LEFT JOIN pg_type AS t2
          ON t1.inputtype=t2.oid
          LEFT JOIN pg_description AS d ON t1.oid=d.objoid
          ORDER BY t1.oid;
        SQL
      end

      it "should return a list of functions in the schema" do
        instance.should_not be_connected
        db = Sequel.connect(db_url)
        instance.functions.should == db.fetch(schema_functions_sql).all
        instance.should_not be_connected
        db.disconnect
      end
    end
  end
end
