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
        SELECT DISTINCT databasenamei as NAME
        FROM DBC.DBASE
      SQL
    }

    let(:expected) { db.fetch(schema_list_sql).all.map { |row| row[:name].downcase.to_sym } }
    let(:subject) { connection.schemas }
    let(:match_array_in_any_order) { true }

    it_should_behave_like 'a well-behaved database query'
  end

end
