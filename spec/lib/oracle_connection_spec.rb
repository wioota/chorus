require 'spec_helper'

describe OracleConnection, :oracle_integration do
  let(:username) { OracleIntegration.username }
  let(:password) { OracleIntegration.password }
  let(:db_name) { OracleIntegration.db_name }
  let(:host) { OracleIntegration.hostname }
  let(:port) { OracleIntegration.port }
  let(:db_url) { OracleIntegration.db_url }
  let(:db) { Sequel.connect(db_url) }

  let(:details) {
    {
        :host => host,
        :username => username,
        :password => password,
        :port => port,
        :database => db_name,
        :logger => Rails.logger
    }
  }
  let(:connection) { OracleConnection.new(details) }

  before do
    stub.proxy(Sequel).connect.with_any_args
    details.delete(:logger)
  end

  describe "#connect!" do
    it "should connect" do
      mock.proxy(Sequel).connect(db_url, hash_including(:test => true))

      connection.connect!
      connection.connected?.should be_true
    end

    context "when oracle is not configured" do
      before do
        stub(ChorusConfig.instance).oracle_configured? { false }
      end

      it "raises an error" do
        expect {
          connection.connect!
        }.to raise_error(DataSourceConnection::DriverNotConfigured) { |error|
          error.data_source.should == 'Oracle'
        }
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

  describe "#schemas" do
    let(:schema_blacklist) {
      ["OBE", "SCOTT", "DIP", "ORACLE_OCM", "XS$NULL", "MDDATA", "SPATIAL_WFS_ADMIN_USR", "SPATIAL_CSW_ADMIN_USR", "IX", "SH", "PM", "BI", "DEMO", "HR1", "OE1", "XDBPM", "XDBEXT", "XFILES", "APEX_PUBLIC_USER", "TIMESTEN", "CACHEADM", "PLS", "TTHR", "APEX_REST_PUBLIC_USER", "APEX_LISTENER", "OE", "HR", "HR_TRIG", "PHPDEMO", "APPQOSSYS", "WMSYS", "OWBSYS_AUDIT", "OWBSYS", "SYSMAN", "EXFSYS", "CTXSYS", "XDB", "ANONYMOUS", "OLAPSYS", "APEX_040200", "ORDSYS", "ORDDATA", "ORDPLUGINS", "FLOWS_FILES", "SI_INFORMTN_SCHEMA", "MDSYS", "DBSNMP", "OUTLN", "MGMT_VIEW", "SYSTEM", "SYS"]
    }

    let(:schema_list_sql) {
      blacklist = schema_blacklist.join("', '")
      <<-SQL
        SELECT DISTINCT OWNER as name
        FROM ALL_OBJECTS
        WHERE OBJECT_TYPE IN ('TABLE', 'VIEW') AND OWNER NOT IN ('#{blacklist}')
      SQL
    }

    let(:expected) { db.fetch(schema_list_sql).all.collect { |row| row[:name] } }
    let(:subject) { connection.schemas }

    it_should_behave_like "a well-behaved database query"
  end

  describe "#schema_exists?" do
    let(:schema_name) { OracleIntegration.schema_name }
    let(:subject) { connection.schema_exists?(schema_name) }
    let(:expected) { true }

    it_should_behave_like "a well-behaved database query"

    context "when the schema doesn't exist" do
      let(:schema_name) { "does_not_exist" }

      it 'returns false' do
        connection.schema_exists?(schema_name).should be_false
      end
    end
  end

  describe "#set_timeout" do
    let (:statement) { Object.new }

    it "calls setQueryTimeout on statement" do
      mock(statement).set_query_timeout(123)
      connection.set_timeout(123, statement)
    end

  end

  describe "#version" do
    it "returns the Oracle connection" do
      connection.version.should == '11.2.0.2.0'
    end
  end

  describe "#stream_sql" do
    let(:sql) { "SELECT * from \"#{OracleIntegration.schema_name}\".NEWTABLE" }

    let(:subject) {
      connection.stream_sql(sql) { true }
    }
    let(:expected) { true }

    it_behaves_like "a well-behaved database query"

    it "streams all rows of the results" do
      bucket = []
      connection.stream_sql(sql) { |row| bucket << row }

      bucket.length.should == 10
      bucket.each_with_index do |row, index|
        index = index + 1
        row.should == {:ID => index.to_s, :ROWNAME => "row_#{index}"}
      end
    end

    context "when a limit is provided" do
      it "only processes part of the results" do
        bucket = []
        connection.stream_sql(sql, {:limit => 1}) { |row| bucket << row }

        bucket.should == [{:ID => "1", :ROWNAME => "row_1"}]
      end
    end
  end

  describe "#prepare_and_execute_statement" do
    context "when a timeout is specified" do
      let(:options) { {:timeout => 1} }
      let(:too_many_rows) { 2500 }
      let(:sql) do
        sql = <<-SQL
            INSERT INTO "#{OracleIntegration.schema_name}".BIG_TABLE
        SQL
        sql + (1..too_many_rows).map do |count|
          <<-SQL
            (SELECT #{count} FROM "#{OracleIntegration.schema_name}".BIG_TABLE)
          SQL
        end.join(" UNION ")
      end

      around do |example|
        connection.execute(<<-SQL) rescue nil
          CREATE TABLE "#{OracleIntegration.schema_name}".BIG_TABLE
            (COLUMN1 NUMBER)
        SQL

        connection.execute <<-SQL
            INSERT INTO "#{OracleIntegration.schema_name}".BIG_TABLE VALUES (0)
        SQL

        example.run

        connection.execute <<-SQL
          DROP TABLE "#{OracleIntegration.schema_name}".BIG_TABLE
        SQL
      end

      it "should raise a timeout error (which is 'requested cancel' on oracle)" do
        expect do
          connection.prepare_and_execute_statement sql, options
        end.to raise_error(DataSourceConnection::QueryError, /requested cancel/)
      end
    end
  end

  describe "methods within a schema" do
    let(:schema_name) { OracleIntegration.schema_name }
    let(:connection) { OracleConnection.new(details.merge(:schema => schema_name)) }

    describe "#datasets" do
      let(:dataset_list_sql) {
        <<-SQL
        SELECT * FROM (
          SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
          UNION
          SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}'
        )
        ORDER BY name
        SQL
      }

      let(:expected) { db.fetch(dataset_list_sql).all }
      let(:subject) { connection.datasets }

      it_should_behave_like "a well-behaved database query"

      context "when a limit is passed" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT * FROM (
          SELECT * FROM (
            SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}'
            UNION
            SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
          )
          ORDER BY name
        )
        WHERE rownum <= 2
          SQL
        }

        let(:expected) { db.fetch(dataset_list_sql).all }
        let(:subject) { connection.datasets(:limit => 2) }

        it_should_behave_like "a well-behaved database query"
      end

      context "when a name filter is passed" do
        let(:subject) { connection.datasets(:name_filter => name_filter) }

        context "and the filter does not contain LIKE wildcards" do
          let(:name_filter) {'nEWer'}
          let(:dataset_list_sql) {
            <<-SQL
          SELECT * FROM (
            SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
            UNION
            SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i'))
          ORDER BY name
            SQL
          }
          let(:expected) { db.fetch(dataset_list_sql).all }

          it_should_behave_like "a well-behaved database query"
        end

        context "and the filter contains LIKE wildcards" do
          let(:name_filter) {'_T'}

          it "only returns datasets which contain '_T' in their names (it should not use _ as a wildcard)" do
            subject.length.should > 0
            subject.each { |dataset| dataset[:name].should include "_T" }
          end
        end
      end

      context "when showing only tables" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
        ORDER BY name
          SQL
        }
        let(:expected) { db.fetch(dataset_list_sql).all }
        let(:subject) { connection.datasets(:tables_only => true) }

        it_should_behave_like "a well-behaved database query"
      end

      context "when multiple options are passed" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT * FROM (
          SELECT * FROM (
            SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
            UNION
            SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i')
          )
          ORDER BY name
        )
        WHERE rownum <= 1
          SQL
        }
        let(:expected) { db.fetch(dataset_list_sql).all }
        let(:subject) { connection.datasets(:name_filter => 'nEWer', :limit => 1) }

        it_should_behave_like "a well-behaved database query"
      end
    end

    describe "#datasets_count" do
      let(:connection) { OracleConnection.new(details.merge(:schema => schema_name)) }
      let(:schema_name) { OracleIntegration.schema_name }
      let(:dataset_list_sql) {
        <<-SQL
        SELECT count(*) FROM (
          SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
          UNION
          SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}'
        )
        SQL
      }

      let(:expected) { db.fetch(dataset_list_sql).single_value }
      let(:subject) { connection.datasets_count }

      it_should_behave_like "a well-behaved database query"

      context "when a name filter is passed" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT count(*) FROM (
          SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
          UNION
          SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i')
        )
          SQL
        }
        let(:expected) { db.fetch(dataset_list_sql).single_value }
        let(:subject) { connection.datasets_count(:name_filter => 'nEWer') }

        it_should_behave_like "a well-behaved database query"
      end

      context "when showing only tables" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT count(*) FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
          SQL
        }
        let(:expected) { db.fetch(dataset_list_sql).single_value }
        let(:subject) { connection.datasets_count(:tables_only => true) }

        it_should_behave_like "a well-behaved database query"
      end
    end

    describe "#metadata_for_dataset" do
      let(:schema_name) { OracleIntegration.schema_name }
      let(:expected) { {:column_count => 2} }
      let(:subject) { connection.metadata_for_dataset('TWO_COLUMN_TABLE') }

      it_should_behave_like "a well-behaved database query"
    end

    describe "#table_exists?" do
      let(:subject) { connection.table_exists?(table_name) }
      let(:expected) { true }

      context "when the table exists" do
        let(:table_name) { "NEWTABLE" }

        it_should_behave_like "a well-behaved database query"
      end

      context "when the table doesn't exist" do
        let(:table_name) { "MISSING_TABLE" }
        let(:expected) { false }

        it_should_behave_like "a well-behaved database query"
      end

      context "when the table name given is nil" do
        let(:table_name) { nil }
        let(:expected) { false }

        it_should_behave_like "a well-behaved database query"
      end
    end

    describe "#view_exists?" do
      let(:subject) { connection.view_exists?(view_name) }

      context "when the view exists" do
        let(:expected) { true }
        let(:view_name) { "NEWVIEW" }

        it_behaves_like 'a well-behaved database query'
      end

      context "when the view doesn't exist" do
        let(:view_name) { "MISSING_VIEW" }
        let(:expected) { false }

        it_behaves_like 'a well-behaved database query'
      end

      context "when the view name given is nil" do
        let(:view_name) { nil }
        let(:expected) { false }

        it_behaves_like 'a well-behaved database query'
      end
    end

    describe "#column_info" do
      let(:table_name) { "NEWERTABLE" }
      let(:columns_sql) do
        <<-SQL
          SELECT COLUMN_NAME as attname, DATA_TYPE as format_type, COLUMN_ID as attnum
          FROM ALL_TAB_COLUMNS
          WHERE TABLE_NAME = :table AND OWNER = :schema
          ORDER BY attnum
        SQL
      end
      let(:expected) do
        db.fetch(columns_sql, :schema => schema_name, :table => table_name).all
      end

      let(:subject) { connection.column_info(table_name, 'ignored setup sql to be consistent with other datasource connections') }

      it_should_behave_like "a well-behaved database query"
    end

    describe "primary_key_columns" do
      context "with a primary key" do
        let(:expected) { %w(COLUMN2 COLUMN1) }
        let(:subject) { connection.primary_key_columns('WITH_COMPOSITE_KEY') }
        it_should_behave_like "a well-behaved database query"
      end

      context "without a primary key" do
        let(:expected) { [] }
        let(:subject) { connection.primary_key_columns('NEWTABLE') }

        it_should_behave_like "a well-behaved database query"
      end
    end
  end

  describe "OracleConnection::DatabaseError" do
    let(:sequel_exception) {
      obj = Object.new
      wrp_exp = Object.new
      stub(obj).wrapped_exception { wrp_exp }
      stub(obj).message { "A message" }
      obj
    }

    let(:error) do
      OracleConnection::DatabaseError.new(sequel_exception)
    end

    describe "error_type" do
      context "when the wrapped error has an error code" do
        before do
          stub(sequel_exception.wrapped_exception).get_error_code { error_code }
        end

        context "when the error code is 12514" do
          let(:error_code) { 12514 }

          it "returns :DATABASE_MISSING" do
            error.error_type.should == :DATABASE_MISSING
          end
        end

        context "when the error code is 1017" do
          let(:error_code) { 1017 }

          it "returns :INVALID_PASSWORD" do
            error.error_type.should == :INVALID_PASSWORD
          end
        end

        context "when the error code is 17002" do
          let(:error_code) { 17002 }

          it "returns :INSTANCE_UNREACHABLE" do
            error.error_type.should == :INSTANCE_UNREACHABLE
          end
        end
      end

      context "when the wrapped error has no sql state error code" do
        it "returns :GENERIC" do
          error.error_type.should == :GENERIC
        end
      end
    end

    describe "sanitizing exception messages" do
      let(:error) { OracleConnection::DatabaseError.new(StandardError.new(message)) }

      let(:message) do
        "foo jdbc:oracle:thin:system/oracle@//chorus-oracle:8888/orcl and stuff"
      end

      it "should sanitize the connection string" do
        error.message.should == "foo jdbc:oracle:thin:xxxx/xxxx@//chorus-oracle:8888/orcl and stuff"
      end
    end
  end
end