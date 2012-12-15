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

  shared_examples "a well behaved database query" do
    let(:db) { Sequel.connect(db_url) }

    it "should match" do
      instance.should_not be_connected
      subject.should == expected
      instance.should_not be_connected
      db.disconnect
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
      let(:expected) { db.fetch(schema_list_sql).all.collect { |row| row[:schema_name] } }
      let(:subject) { instance.schemas }

      it_should_behave_like "a well behaved database query"
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

      let(:expected) { db.fetch(database_list_sql).all.collect { |row| row[:datname] } }
      let(:subject) { instance.databases }

      it_should_behave_like "a well behaved database query"
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
      let(:expected) { db.fetch(schema_functions_sql).all }
      let(:subject) { instance.functions }

      it_should_behave_like "a well behaved database query"
    end

    describe "#disk_space_used" do
      let(:disk_space_sql) do
        <<-SQL
          SELECT sum(pg_total_relation_size(pg_catalog.pg_class.oid))::bigint AS size
          FROM   pg_catalog.pg_class
          LEFT JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
          WHERE  pg_catalog.pg_namespace.nspname = '#{schema_name}'
        SQL
      end
      let(:schema_name) { 'test_schema3' }
      let(:expected) { db.fetch(disk_space_sql).single_value }
      let(:subject) { instance.disk_space_used }

      it_should_behave_like "a well behaved database query"
    end

    describe "#table_exists?" do
      context "when the table exists" do
        let(:table_name) { "different_names_table" }

        it "should return true" do
          instance.table_exists?(table_name).should == true
        end
      end

      context "when the table doesn't exist" do
        let(:table_name) { "please_dont_exist" }

        it "should return false" do
          instance.table_exists?(table_name).should == false
        end
      end

      context "when the table name given is nil" do
        let(:table_name) { nil }

        it "should return false" do
          instance.table_exists?(table_name).should == false
        end
      end
    end

    describe "#analyze_table" do
      context "when the table exists" do
        let(:table_name) { "table_to_analyze" }

        before do
          stub.proxy(Sequel).connect do |connection|
            mock(connection).execute(%Q{ANALYZE "#{schema_name}"."#{table_name}"})
          end
        end

        it "analyzes the table" do
          instance.analyze_table(table_name)
        end
      end

      context "when the table does not exist" do
        let(:table_name) { "this_table_does_not_exist" }

        it "throws an error to the layer above" do
          expect do
            instance.analyze_table(table_name)
          end.to raise_error(Sequel::DatabaseError)
        end
      end
    end
  end
end
