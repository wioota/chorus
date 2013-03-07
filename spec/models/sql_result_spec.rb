require 'spec_helper'

describe SqlResult, :oracle_integration do
  let(:username) { OracleIntegration.username }
  let(:password) { OracleIntegration.password }
  let(:db_name) { OracleIntegration.db_name }
  let(:host) { OracleIntegration.hostname }
  let(:port) { OracleIntegration.port }
  let(:db_url) { OracleIntegration.db_url }
  let(:db) { Sequel.connect(db_url) }

  let(:details) do
    {
        :host => host,
        :username => username,
        :password => password,
        :port => port,
        :database => db_name,
        :logger => Rails.logger
    }
  end
  let(:connection) { OracleConnection.new(details) }

  before do
    stub.proxy(Sequel).connect.with_any_args
    details.delete(:logger)
  end

  describe "load_from_result_set" do
    let(:schema_name) { OracleIntegration.schema_name }
    let(:table_name) { "ALL_COLUMN_TABLE" }

    context "when a limit is set" do
      let(:options) do
        {
            :limit => 1
        }
      end

      it "does not raise an error caused by a LONG value" do
        expect {
          connection.prepare_and_execute_statement "SELECT * FROM \"#{schema_name}\".\"#{table_name}\"", options
        }.not_to raise_error
      end

      describe "connecting to greenplum", :greenplum_integration do
        let(:data_source) { GreenplumIntegration.real_data_source }
        let(:schema) { GreenplumIntegration.real_database.schemas.first }
        let(:account) { data_source.owner_account }
        let(:table_name) { "binary_columns_table"}

        before do
          schema.connect_with(account).execute("CREATE TABLE #{table_name} (col1 float8, col2 float8)")
          schema.connect_with(account).execute("INSERT INTO #{table_name} VALUES(2.3, 5.3)")
        end

        after do
          schema.connect_with(account).execute("DROP TABLE #{table_name}")
        end

        it "properly formats binary floats" do
          rs = schema.connect_with(account).prepare_and_execute_statement "SELECT * FROM \"#{table_name}\""
          rs.rows[0][0].should == "2.3"
          rs.rows[0][1].should == "5.3"
        end
      end

      describe "connecting to oracle" do
        let(:schema) { OracleIntegration.real_schema }
        let(:account) { OracleIntegration.real_account }
        let(:table_name) { "ALL_COLUMN_TABLE" }

        it "properly formats DATE columns" do
          rs = schema.connect_with(account).prepare_and_execute_statement "SELECT DAY FROM \"#{schema_name}\".\"#{table_name}\""
          rs.rows[0][0].should == "12/23/2011"
        end

        it "properly formats TIMESTAMP columns" do
          rs = schema.connect_with(account).prepare_and_execute_statement "SELECT TIMESTAMP_COL FROM \"#{schema_name}\".\"#{table_name}\""
          rs.rows[0][0].should == "9/10/2002 2:10:10.123 PM"
        end
      end
    end
  end
end