require 'spec_helper'

describe Schemas::ImportsController, :greenplum_integration => true, :oracle_integration => true, :type => :controller do
  let(:user) { users(:owner) }
  let(:source_table) { OracleIntegration.real_schema.datasets.find_by_name('ALL_COLUMN_TABLE') }
  let(:schema) { GpdbSchema.find_by_name('test_schema') }

  let(:params) do
    {
        :schema_id => schema.to_param,
        :dataset_id => source_table.to_param,
        :truncate => "false"
    }
  end

  before do
    clean_up_tables
    run_jobs_synchronously
    log_in user
  end

  after do
    clean_up_tables
  end

  it "can perform an import into a new table" do
    post :create, params.merge(:new_table => "true", :to_table => "some_new_table")
    response.code.should eq("201")

    results = GreenplumIntegration.exec_sql_line("select * from \"#{schema.name}\".some_new_table;")

    results.first["BIN_DOUBLE"].to_f.should eq(2.3)
    results.first["CHARACTER"].should eq('c')
    results.first["CHAR_BLOB"].should eq('some long text and stuff')
    results.first["DAY"].should eq('2011-12-23 00:00:00')
  end

  it "can perform an import into an existing table" do
    create_existing_table
    populate_existing_table

    post :create, params.merge(:new_table => "false", :to_table => "existing_table")
    response.code.should eq("201")

    results = GreenplumIntegration.exec_sql_line("select * from \"#{schema.name}\".existing_table order by \"BIN_DOUBLE\";")
    results.second["BIN_DOUBLE"].to_f.should eq(2.4)
    results.second["CHARACTER"].should eq('d')
    results.second["CHAR_BLOB"].should eq('some other long text and other stuff')
    results.second["DAY"].should eq('2011-12-24 00:00:00')
  end
end

def create_existing_table
  create_table_sql = <<-SQL
      CREATE TABLE "#{schema.name}".existing_table (
        "BIN_DOUBLE" double precision
      , "BIN_FLOAT" double precision
      , "CHARACTER" character(1)
      , "CHAR_BLOB" text
      , "DAY" timestamp without time zone
      , "DECIMAL_COL" numeric
      , "INTEGER_COL" numeric
      , "UNICODE_CHAR" character(1)
      , "UNICODE_CLOB" text
      , "NUMBER_COL" numeric
      , "UNICODE_VARCHAR" character varying
      , "ROW_ID" text
      , "TIMESTAMP_COL" timestamp without time zone
      , "UNIVERSAL_ROW_ID" text
      , "VARIABLE_CHARACTER" character varying
      , "VARIABLE_CHARACTER_2" character varying
      , "LONG_COLUMN" text
      );
  SQL

  GreenplumIntegration.exec_sql_line(create_table_sql)
  schema.refresh_datasets(GreenplumIntegration.real_account)
end

def populate_existing_table
  insert_values_sql = <<-SQL2
      INSERT INTO "#{schema.name}".existing_table VALUES (
        2.4,
        5.4,
        'd',
        'some other long text and other stuff',
        to_date('2011-12-24', 'YYYY-MM-DD'),
        123,
        43,
        'W',
        'long other thingy',
        433,
        'other stuff',
        NULL,
        TO_TIMESTAMP('10-SEP-0214:10:10.123001','DD-MON-RRHH24:MI:SS.FF'),
        NULL,
        'some other string',
        'another some other string so there shutup',
        'not actually very long content'
      );
  SQL2

  GreenplumIntegration.exec_sql_line(insert_values_sql)
end

def clean_up_tables
  GreenplumIntegration.exec_sql_line("DROP TABLE IF EXISTS #{schema.name}.some_new_table;")
  GreenplumIntegration.exec_sql_line("DROP TABLE IF EXISTS #{schema.name}.existing_table;")
end

