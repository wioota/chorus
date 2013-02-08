require 'spec_helper'

describe OracleConnection, :oracle_integration do
  before(:all) do
    require Rails.root + 'lib/libraries/ojdbc6.jar'
  end

  let(:username) { InstanceIntegration.oracle_username }
  let(:password) { InstanceIntegration.oracle_password }
  let(:db_name) { InstanceIntegration.oracle_db_name }
  let(:host) { InstanceIntegration.oracle_hostname }
  let(:port) { InstanceIntegration.oracle_port }
  let(:db_url) { "jdbc:oracle:thin:#{username}/#{password}@//#{host}:#{port}/#{db_name}" }
  let(:db) { Sequel.connect(db_url) }

  let(:details) {
    {
        :host => host,
        :username => username,
        :password => password,
        :port => port,
        :database => db_name
    }
  }
  let(:connection) { OracleConnection.new(details) }

  before do
    stub.proxy(Sequel).connect.with_any_args
  end

  describe "#connect!" do
    it "should connect" do
      mock.proxy(Sequel).connect(db_url, :test => true)

      connection.connect!
      connection.connected?.should be_true
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

    it_should_behave_like "a well behaved database query"
  end

  describe "#schema_exists?" do
    let(:schema_name) { InstanceIntegration.oracle_schema_name }
    let(:subject) { connection.schema_exists?(schema_name) }
    let(:expected) { true }

    it_should_behave_like "a well behaved database query"

    context "when the schema doesn't exist" do
      let(:schema_name) { "does_not_exist" }

      it 'returns false' do
        connection.schema_exists?(schema_name).should be_false
      end
    end
  end

  describe "#datasets" do
    let(:connection) { OracleConnection.new(details.merge(:schema => schema_name)) }
    let(:schema_name) { InstanceIntegration.oracle_schema_name }
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

    it_should_behave_like "a well behaved database query"

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

      it_should_behave_like "a well behaved database query"
    end

    context "when a name filter is passed" do
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
      let(:subject) { connection.datasets(:name_filter => 'nEWer') }

      it_should_behave_like "a well behaved database query"
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

      it_should_behave_like "a well behaved database query"
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

      it_should_behave_like "a well behaved database query"
    end
  end

  describe "#datasets_count" do
    let(:connection) { OracleConnection.new(details.merge(:schema => schema_name)) }
    let(:schema_name) { InstanceIntegration.oracle_schema_name }
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

    it_should_behave_like "a well behaved database query"

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

      it_should_behave_like "a well behaved database query"
    end

    context "when showing only tables" do
      let(:dataset_list_sql) {
        <<-SQL
        SELECT count(*) FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
        SQL
      }
      let(:expected) { db.fetch(dataset_list_sql).single_value }
      let(:subject) { connection.datasets_count(:tables_only => true) }

      it_should_behave_like "a well behaved database query"
    end
  end

  describe "#metadata_for_dataset" do
    let(:metadata_sql) {
      <<-SQL
      SELECT COUNT(*) AS column_count FROM ALL_TAB_COLUMNS WHERE TABLE_NAME = 'NEWERTABLE'
      SQL
    }
    let(:expected) { db.fetch(metadata_sql).first }
    let(:subject) { connection.metadata_for_dataset('NEWERTABLE') }

    it_should_behave_like "a well behaved database query"
  end

  describe "#version" do
    it "returns the Oracle connection" do
      connection.version.should == '11.2.0.2.0'
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
          let(:error_code) { 12514}

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