require 'spec_helper'

describe JdbcConnection, :jdbc_integration do

  let(:data_source) { JdbcIntegration.real_data_source }
  let(:account) { JdbcIntegration.real_account }
  let(:options) { { :logger => Rails.logger } }
  let(:connection) { JdbcConnection.new(data_source, account, options) }

  let(:db_url) { connection.db_url }
  let(:db_options) { connection.db_options }
  let(:db) { Sequel.connect(db_url, db_options) }

  describe '#connect!' do
    it 'connects!' do
      mock.proxy(Sequel).connect(db_url, hash_including(:test => true))

      connection.connect!
      connection.connected?.should be_true
    end
  end

  describe '#schemas' do
    let(:schema_list_sql) {
      <<-SQL
        SELECT DISTINCT databasename as name
        FROM DBC.DBASE
      SQL
    }

    let(:expected) { db.fetch(schema_list_sql).all.map { |row| row[:name] } }
    let(:subject) { connection.schemas }
    let(:use_match_matcher) { true }

    it_should_behave_like 'a well-behaved database query'
  end

  describe '#schema_exists?' do
    let(:schema_name) { JdbcIntegration.schema_name }
    let(:subject) { connection.schema_exists?(schema_name) }
    let(:expected) { true }

    it_should_behave_like 'a well-behaved database query'

    context 'when the schema does not exist' do
      let(:schema_name) { 'does_not_exist' }

      it 'returns false' do
        connection.schema_exists?(schema_name).should be_false
      end
    end
  end

  describe 'methods within a schema' do
    let(:schema_name) { JdbcIntegration.schema_name }
    let(:connection) { JdbcConnection.new(data_source, account, options.merge(:schema => schema_name)) }

    describe '#datasets' do

      context 'fetching all tables and views' do
        let(:dataset_list_sql) {
          <<-SQL
          SELECT tablename AS name, tablekind as ttype FROM dbc.tables where databasename = '#{schema_name}' ORDER BY name
          SQL
        }

        let(:expected) { db.fetch(dataset_list_sql).map { |row| {:name => row[:name].strip, :type => row[:ttype] == 'T' ? 't' : 'v' } } }
        let(:subject) { connection.datasets }
        let(:use_match_matcher) { true }

        it_should_behave_like 'a well-behaved database query'
      end

      context 'when a limit is passed' do
        let(:expected) { 2 }
        let(:subject) { connection.datasets(:limit => 2).size }

        it_should_behave_like 'a well-behaved database query'
      end

      context 'when a name filter is passed' do
        let(:subject) { connection.datasets(:name_filter => name_filter) }

        context 'and the filter does not contain LIKE wildcards' do
          let(:name_filter) {'nEWer'}
          let(:dataset_list_sql) {
            <<-SQL
          SELECT tablename AS name, tablekind as ttype FROM dbc.tables where databasename = '#{schema_name}' and name LIKE '%#{name_filter}%' (NOT CASESPECIFIC) ORDER BY name
            SQL
          }
          let(:expected) { db.fetch(dataset_list_sql).map { |row| {:name => row[:name].strip, :type => row[:ttype] == 'T' ? 't' : 'v' } } }

          it_should_behave_like 'a well-behaved database query'
        end

        context 'and the filter contains LIKE wildcards' do
          let(:name_filter) {'_T'}

          it 'only returns datasets which contain `_T` in their names (it should not use _ as a wildcard)' do
            subject.length.should > 0
            subject.each { |dataset| dataset[:name].should match /_T/i }
          end
        end
      end

      #context 'when showing only tables' do
      #  let(:dataset_list_sql) {
      #    <<-SQL
      #  SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
      #  ORDER BY name
      #    SQL
      #  }
      #  let(:expected) { db.fetch(dataset_list_sql).all }
      #  let(:subject) { connection.datasets(:tables_only => true) }
      #
      #  it_should_behave_like 'a well-behaved database query'
      #end

      #context 'when multiple options are passed' do
      #  let(:dataset_list_sql) {
      #    <<-SQL
      #  SELECT * FROM (
      #    SELECT * FROM (
      #      SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
      #      UNION
      #      SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i')
      #    )
      #    ORDER BY name
      #  )
      #  WHERE rownum <= 1
      #    SQL
      #  }
      #  let(:expected) { db.fetch(dataset_list_sql).all }
      #  let(:subject) { connection.datasets(:name_filter => 'nEWer', :limit => 1) }
      #
      #  it_should_behave_like 'a well-behaved database query'
      #end
    end

    describe '#datasets_count' do
      let(:connection) { JdbcConnection.new(data_source, account, options.merge(:schema => schema_name)) }
      let(:schema_name) { JdbcIntegration.schema_name }
      let(:dataset_list_sql) {
        <<-SQL
          SELECT COUNT(*) FROM dbc.tables where databasename = '#{schema_name}'
        SQL
      }

      let(:expected) { db.fetch(dataset_list_sql).single_value }
      let(:subject) { connection.datasets_count }

      it_should_behave_like 'a well-behaved database query'

    #  context 'when a name filter is passed' do
    #    let(:dataset_list_sql) {
    #      <<-SQL
    #    SELECT count(*) FROM (
    #      SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
    #      UNION
    #      SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i')
    #    )
    #      SQL
    #    }
    #    let(:expected) { db.fetch(dataset_list_sql).single_value }
    #    let(:subject) { connection.datasets_count(:name_filter => 'nEWer') }
    #
    #    it_should_behave_like 'a well-behaved database query'
    #  end
    #
    #  context 'when showing only tables' do
    #    let(:dataset_list_sql) {
    #      <<-SQL
    #    SELECT count(*) FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
    #      SQL
    #    }
    #    let(:expected) { db.fetch(dataset_list_sql).single_value }
    #    let(:subject) { connection.datasets_count(:tables_only => true) }
    #
    #    it_should_behave_like 'a well-behaved database query'
    #  end
    end

    describe '#metadata_for_dataset' do
      let(:schema_name) { JdbcIntegration.schema_name }
      let(:expected) { {:column_count => 2} }
      let(:subject) { connection.metadata_for_dataset('TWO_COLUMN_TABLE') }

      it_should_behave_like 'a well-behaved database query'

      context 'the table has lowercase characters' do
        let(:expected) { {:column_count => 3} }
        let(:subject) { connection.metadata_for_dataset('lowercase_table') }

        it_should_behave_like 'a well-behaved database query'
      end
    end

    describe '#table_exists?' do
      let(:subject) { connection.table_exists?(table_name) }
      let(:expected) { true }

      context 'when the table exists' do

        context 'with uppercase table name' do
          let(:table_name) { 'NEWTABLE' }
          it_should_behave_like 'a well-behaved database query'
        end

        context 'with a lowercase table name' do
          let(:table_name) { 'lowercase_table' }
          it_should_behave_like 'a well-behaved database query'
        end
      end

      context 'when the table does not exist' do
        let(:table_name) { 'MISSING_TABLE' }
        let(:expected) { false }

        it_should_behave_like 'a well-behaved database query'
      end

      context 'when the table name given is nil' do
        let(:table_name) { nil }
        let(:expected) { false }

        it 'returns false before trying to connect' do
          do_not_allow(Sequel).connect
          subject.should == expected
        end
      end
    end

    describe '#view_exists?' do
      let(:subject) { connection.view_exists?(view_name) }

      context 'when the view exists' do
        let(:expected) { true }

        context 'with uppercase view name' do
          let(:view_name) { 'NEWVIEW' }
          it_should_behave_like 'a well-behaved database query'
        end

        context 'with a lowercase view name' do
          let(:view_name) { 'lowercase_view' }
          it_should_behave_like 'a well-behaved database query'
        end
      end

      context 'when the view does not exist' do
        let(:view_name) { 'MISSING_VIEW' }
        let(:expected) { false }

        it_behaves_like 'a well-behaved database query'
      end

      context 'when the view name given is nil' do
        let(:view_name) { nil }
        let(:expected) { false }

        it 'returns false before trying to connect' do
          do_not_allow(Sequel).connect
          subject.should == expected
        end
      end
    end

    describe '#column_info' do
      let(:table_name) { 'NEWTABLE' }
      let(:columns_sql) do
        <<-SQL
          SELECT
          TRIM(COLUMNNAME) AS attname,
          TRIM(COLUMNTYPE) AS format_type
          FROM (
          SELECT
          COLUMNNAME,
          COLUMNID,
          CASE WHEN COLUMNTYPE='CV' THEN 'VARCHAR'
               WHEN COLUMNTYPE='I' THEN 'INTEGER'
          END AS COLUMNTYPE
          FROM DBC.COLUMNS
          WHERE DATABASENAME=:schema AND TABLENAME=:table ) TBL ORDER BY COLUMNID
        SQL
      end
      let(:expected) do
        db.fetch(columns_sql, :schema => schema_name, :table => table_name).all
      end

      let(:subject) { connection.column_info(table_name, 'ignored setup sql to be consistent with other datasource connections') }

      it_should_behave_like 'a well-behaved database query'
    end

    #describe 'primary_key_columns' do
    #  context 'with a primary key' do
    #    let(:expected) { %w(COLUMN2 COLUMN1) }
    #    let(:subject) { connection.primary_key_columns('WITH_COMPOSITE_KEY') }
    #    it_should_behave_like 'a well-behaved database query'
    #  end
    #
    #  context "without a primary key" do
    #    let(:expected) { [] }
    #    let(:subject) { connection.primary_key_columns('NEWTABLE') }
    #
    #    it_should_behave_like 'a well-behaved database query'
    #  end
    #end
  end

  describe '#version' do
    let(:subject) { connection.version }
    let(:expected) { /Teradata Database 14\.10.*/ }
    let(:use_match_matcher) { true }

    it_should_behave_like 'a well-behaved database query'
  end

  describe '#stream_sql' do
    let(:sql) { %(SELECT * from "#{JdbcIntegration.schema_name}".NEWTABLE) }

    let(:subject) { connection.stream_sql(sql) { true } }
    let(:expected) { true }

    it_behaves_like 'a well-behaved database query'

    it 'streams all rows of the results' do
      bucket = []
      connection.stream_sql(sql) { |row| bucket << row }

      bucket.length.should == 10
      bucket.each_with_index do |row, index|
        row[:rowname].should == "row_#{row[:id]}"
      end
    end

    it 'stores the statement through the cancelable_query' do
      cancelable_query = Object.new
      mock(cancelable_query).store_statement.with_any_args
      connection.stream_sql(sql, {}, cancelable_query) {}
    end

    context 'when a limit is provided' do
      it 'only processes part of the results' do
        bucket = []
        connection.stream_sql(sql, {:limit => 1}) { |row| bucket << row }

        bucket.size.should == 1
        row = bucket.first
        row[:rowname].should == "row_#{row[:id]}"
      end
    end
  end

  describe '#prepare_and_execute_statement' do
    let(:sql) { %(SELECT * from "#{JdbcIntegration.schema_name}".NEWTABLE) }

    it 'stores the statement through the cancelable_query' do
      cancelable_query = Object.new
      mock(cancelable_query).store_statement.with_any_args
      connection.prepare_and_execute_statement(sql, {}, cancelable_query)
    end
  end

  describe '#create_sql_result' do
    it 'returns a JdbcSqlResult' do
      connection.create_sql_result('warnings', nil).should be_a JdbcSqlResult
    end
  end

  describe '#set_timeout' do
    let (:statement) { Object.new }

    it 'calls setQueryTimeout on statement' do
      mock(statement).set_query_timeout(123)
      connection.set_timeout(123, statement)
    end

  end
end
