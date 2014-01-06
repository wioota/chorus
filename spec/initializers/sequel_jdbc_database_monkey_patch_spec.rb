require 'spec_helper'

describe 'Sequel JDBC Monkey Patch', :jdbc_integration do
  let(:data_source) { JdbcIntegration.real_data_source }
  let(:account) { JdbcIntegration.real_account }
  let(:options) { { :logger => Rails.logger } }
  let(:connection) { JdbcConnection.new(data_source, account, options) }

  let(:opts) { {:schema => JdbcIntegration.schema_name} }

  context 'overriding methods' do
    context '#tables' do
      it 'returns a list of symbols' do
        tables = connection.with_connection { |c| c.tables opts }
        tables.count.should > 0
        tables.each { |t| t.should be_a(Symbol) }
      end
    end

    context '#views' do
      it 'returns a list of symbols' do
        views = connection.with_connection { |c| c.views opts }
        views.count.should > 0
        views.each { |v| v.should be_a(Symbol) }
      end
    end
  end
end