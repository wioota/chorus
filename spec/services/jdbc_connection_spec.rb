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

    let(:expected) { db.fetch(schema_list_sql).all.map { |row| row[:name].to_sym } }
    let(:subject) { connection.schemas }
    let(:match_array_in_any_order) { true }

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
      let(:dataset_list_sql) {
        <<-SQL
        SELECT tablename AS name, tablekind as ttype FROM dbc.tables where databasename = '#{schema_name}' ORDER BY name
        SQL
      }

      let(:expected) { db.fetch(dataset_list_sql).map { |row| {:name => row[:name].strip, :type => row[:ttype] == 'T' ? 't' : 'v' } } }
      let(:subject) { connection.datasets }
      let(:match_array_in_any_order) { true }

      it_should_behave_like 'a well-behaved database query'

      #context 'when a limit is passed' do
      #  let(:dataset_list_sql) {
      #    <<-SQL
      #  SELECT * FROM (
      #    SELECT * FROM (
      #      SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}'
      #      UNION
      #      SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
      #    )
      #    ORDER BY name
      #  )
      #  WHERE rownum <= 2
      #    SQL
      #  }
      #
      #  let(:expected) { db.fetch(dataset_list_sql).all }
      #  let(:subject) { connection.datasets(:limit => 2) }
      #
      #  it_should_behave_like 'a well-behaved database query'
      #end

      #context 'when a name filter is passed' do
      #  let(:subject) { connection.datasets(:name_filter => name_filter) }
      #
      #  context 'and the filter does not contain LIKE wildcards' do
      #    let(:name_filter) {'nEWer'}
      #    let(:dataset_list_sql) {
      #      <<-SQL
      #    SELECT * FROM (
      #      SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
      #      UNION
      #      SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i'))
      #    ORDER BY name
      #      SQL
      #    }
      #    let(:expected) { db.fetch(dataset_list_sql).all }
      #
      #    it_should_behave_like 'a well-behaved database query'
      #  end
      #
      #  context 'and the filter contains LIKE wildcards' do
      #    let(:name_filter) {'_T'}
      #
      #    it 'only returns datasets which contain '_T' in their names (it should not use _ as a wildcard)' do
      #      subject.length.should > 0
      #      subject.each { |dataset| dataset[:name].should include "_T" }
      #    end
      #  end
      #end

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

        it_should_behave_like 'a well-behaved database query'
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

        it_behaves_like 'a well-behaved database query'
      end
    end

    #describe '#column_info' do
    #  let(:table_name) { 'NEWERTABLE' }
    #  let(:columns_sql) do
    #    <<-SQL
    #      SELECT COLUMN_NAME as attname, DATA_TYPE as format_type, COLUMN_ID as attnum
    #      FROM ALL_TAB_COLUMNS
    #      WHERE TABLE_NAME = :table AND OWNER = :schema
    #      ORDER BY attnum
    #    SQL
    #  end
    #  let(:expected) do
    #    db.fetch(columns_sql, :schema => schema_name, :table => table_name).all
    #  end
    #
    #  let(:subject) { connection.column_info(table_name, 'ignored setup sql to be consistent with other datasource connections') }
    #
    #  it_should_behave_like 'a well-behaved database query'
    #end

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
end
