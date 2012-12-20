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

  let(:connection) { GreenplumConnection::Base.new(details) }

  shared_examples "a well behaved database query" do
    let(:db) { Sequel.connect(db_url) }

    it "should match" do
      connection.should_not be_connected
      subject.should == expected
      connection.should_not be_connected
      db.disconnect
    end
  end

  describe "#connect!" do
    before do
      mock.proxy(Sequel).connect(db_url, hash_including(:test => true))
    end

    context "with valid credentials" do
      it "connects successfully" do
        connection.connect!
        connection.should be_connected
      end
    end

    context "with incorrect credentials" do
      let(:username) { "not_a_user" }
      let(:password) { "not_a_password" }

      it "raises a GreenplumConnection::InstanceUnreachable error" do
        expect {
          connection.connect!
        }.to raise_error(GreenplumConnection::InstanceUnreachable)
      end
    end

    context "when the database is unreachable" do
      let(:port) { "976543" }

      it "raises a GreenplumConnection::InstanceUnreachable error" do
        expect {
          connection.connect!
        }.to raise_error(GreenplumConnection::InstanceUnreachable)
      end
    end
  end

  describe "#disconnect" do
    before do
      mock_conn = Object.new

      mock(Sequel).connect(anything, anything) { mock_conn }
      mock(mock_conn).disconnect
      connection.connect!
    end

    it "disconnects Sequel connection" do
      connection.should be_connected
      connection.disconnect
      connection.should_not be_connected
    end
  end

  describe GreenplumConnection::DatabaseConnection do
    let(:connection) { GreenplumConnection::DatabaseConnection.new(details) }
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
      let(:subject) { connection.schemas }

      it_should_behave_like "a well behaved database query"
    end

    describe '#schema_exists?' do
      context 'when the schema exists' do
        let(:schema_name) { 'test_schema' }

        it 'returns true' do
          connection.schema_exists?(schema_name).should be_true
        end
      end

      context "when the schema doesn't exist" do
        let(:schema_name) { "does_not_exist" }

        it 'returns false' do
          connection.schema_exists?(schema_name).should be_false
        end
      end
    end

    describe "#create_schema" do
      let(:new_schema_name) { "foobarbaz" }

      after do
        db = Sequel.connect(db_url)
        db.drop_schema(new_schema_name, :if_exists => true)
        db.disconnect
      end

      it "adds a schema" do
        expect {
          connection.create_schema("foobarbaz")
        }.to change { connection.schemas }
      end
    end

    describe "#drop_schema" do
      context "if the schema exists" do
        let(:schema_to_drop) { "hopefully_unused_schema" }

        around do |example|
          db = Sequel.connect(db_url)
          db.create_schema(schema_to_drop)

          example.run

          db.drop_schema(schema_to_drop, :if_exists => true)
          db.disconnect
        end

        it "drops it" do
          connection.schema_exists?(schema_to_drop).should == true
          connection.drop_schema(schema_to_drop)
          connection.schema_exists?(schema_to_drop).should == false
        end
      end

      context "if the schema does not exist" do
        let(:schema_to_drop) { "never_existed" }

        it "doesnt raise an error" do
          expect {
            connection.drop_schema(schema_to_drop)
          }.to_not raise_error
        end
      end
    end


    describe "#fetch" do
      let(:sql) { "SELECT 1 AS answer" }
      let(:parameters) {{}}

      it "succeeds" do
        connection.fetch(sql).should == [{ :answer => 1 }]
      end

      context "with SQL parameters" do
        let(:sql) { "SELECT :num AS answer" }
        let(:parameters) {{:num => 3}}

        it "succeeds" do
          connection.fetch(sql, parameters).should == [{ :answer => 3 }]
        end
      end
    end

    describe "#execute" do
      let(:sql) { "SET search_path TO 'public'" }
      let(:parameters) {{}}

      it "succeeds" do
        expect {
          connection.execute(sql)
        }.to_not raise_error
      end
    end
  end

  describe GreenplumConnection::InstanceConnection do
    let(:connection) { GreenplumConnection::InstanceConnection.new(details) }
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
      let(:subject) { connection.databases }

      it_should_behave_like "a well behaved database query"
    end


    describe "#fetch" do
      let(:sql) { "SELECT 1 AS answer" }
      let(:parameters) {{}}

      it "succeeds" do
        connection.fetch(sql).should == [{ :answer => 1 }]
      end

      context "with SQL parameters" do
        let(:sql) { "SELECT :num AS answer" }
        let(:parameters) {{:num => 3}}

        it "succeeds" do
          connection.fetch(sql, parameters).should == [{ :answer => 3 }]
        end
      end
    end

    describe "#execute" do
      let(:sql) { "SET search_path TO 'public'" }
      let(:parameters) {{}}

      it "succeeds" do
        expect {
          connection.execute(sql)
        }.to_not raise_error
      end
    end
  end

  describe GreenplumConnection::SchemaConnection do
    let(:connection) { GreenplumConnection::SchemaConnection.new(details.merge(:schema => schema_name)) }
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
      let(:subject) { connection.functions }

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
      let(:subject) { connection.disk_space_used }

      it_should_behave_like "a well behaved database query"
    end

    describe '#create_view' do
      context 'when a view with that name does not exist' do
        after do
          db = Sequel.connect(db_url)
          db.default_schema = schema_name
          db.drop_view('a_new_db_view') if connection.view_exists?('a_new_db_view')
          db.disconnect
        end

        it 'creates a view' do
          expect {
            connection.create_view('a_new_db_view', 'select 1;')
          }.to change { Sequel.connect(db_url).views }
        end
      end

      context 'when a view with that name already exists' do
        it 'raises an error' do
          expect {
            connection.create_view('view1', 'select 1;')
          }.to raise_error(GreenplumConnection::SchemaConnection::CannotCreateView, /already exists/)
        end
      end
    end

    describe "#table_exists?" do
      context "when the table exists" do
        let(:table_name) { "different_names_table" }

        it "returns true" do
          connection.table_exists?(table_name).should == true
        end

        context 'when the table has weird chars in the name' do
          let(:table_name) { %Q(7_`~!@#\$%^&*()+=[]{}|\\;:',<.>/?) }

          it 'works (regression)' do
            connection.table_exists?(table_name).should == true
          end
        end
      end

      context "when the table doesn't exist" do
        let(:table_name) { "please_dont_exist" }

        it "returns false" do
          connection.table_exists?(table_name).should == false
        end
      end

      context "when the table name given is nil" do
        let(:table_name) { nil }

        it "returns false" do
          connection.table_exists?(table_name).should == false
        end
      end
    end

    describe "#view_exists?" do
      context "when the view exists" do
        let(:view_name) { "view1" }

        it "returns true" do
          connection.view_exists?(view_name).should == true
        end
      end

      context "when the view doesn't exist" do
        let(:view_name) { "please_dont_exist" }

        it "returns false" do
          connection.view_exists?(view_name).should == false
        end
      end

      context "when the table name given is nil" do
        let(:view_name) { nil }

        it "returns false" do
          connection.view_exists?(view_name).should == false
        end
      end
    end

    describe "#analyze_table" do
      context "when the table exists" do
        let(:table_name) { "table_to_analyze" }

        before do
          stub.proxy(Sequel).connect do |connection|
            stub(connection).execute(anything)
            mock(connection).execute(%Q{ANALYZE "#{schema_name}"."#{table_name}"})
          end
        end

        it "analyzes the table" do
          connection.analyze_table(table_name)
        end
      end

      context "when the table does not exist" do
        let(:table_name) { "this_table_does_not_exist" }

        it "throws an error to the layer above" do
          expect do
            connection.analyze_table(table_name)
          end.to raise_error(Sequel::DatabaseError)
        end
      end
    end

    describe "#drop_table" do
      context "if the table exists" do
        let(:table_to_drop) { "hopefully_unused_table" }

        around do |example|
          db = Sequel.connect(db_url)
          db.default_schema = schema_name
          db.create_table(table_to_drop)

          example.run

          db.drop_table(table_to_drop, :if_exists => true)
          db.disconnect
        end

        it "should drop a table" do
          connection.table_exists?(table_to_drop).should == true
          connection.drop_table(table_to_drop)
          connection.table_exists?(table_to_drop).should == false
        end
      end

      context "if the table does not exist" do
        let(:table_to_drop) { "never_existed" }

        it "raises an error" do
          expect {
            connection.drop_table(table_to_drop)
          }.to_not raise_error
        end
      end
    end

    describe "#truncate_table" do
      context "if the table exists" do
        let(:table_to_truncate) { "trunc_table" }

        before do
          connection.execute(<<-SQL)
            CREATE TABLE "test_schema"."trunc_table" (num integer);
            INSERT INTO "test_schema"."trunc_table" (num) VALUES (2)
          SQL
        end

        after do
          connection.execute(<<-SQL)
            DROP TABLE IF EXISTS "test_schema"."trunc_table"
          SQL
        end

        it "should truncate a table" do
          expect {
            connection.truncate_table(table_to_truncate)
          }.to change { connection.fetch(<<-SQL)[0][:num] }.from(1).to(0)
            SELECT COUNT(*) AS num FROM "test_schema"."trunc_table"
          SQL
        end
      end
    end

    describe "#fetch" do
      let(:sql) { "SELECT 1 AS answer" }
      let(:parameters) {{}}

      it "succeeds" do
        connection.fetch(sql).should == [{ :answer => 1 }]
      end

      context "with SQL parameters" do
        let(:sql) { "SELECT :num AS answer" }
        let(:parameters) {{:num => 3}}

        it "succeeds" do
          connection.fetch(sql, parameters).should == [{ :answer => 3 }]
        end
      end
    end

    describe "#execute" do
      let(:sql) { "SET search_path TO 'public'" }
      let(:parameters) {{}}

      it "succeeds" do
        expect {
          connection.execute(sql)
        }.to_not raise_error
      end
    end
  end
end
