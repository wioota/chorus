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
      let((:options)) do
        {
            :limit => 1
        }
      end

      it "does not raise an error caused by a LONG value" do
        expect {
          connection.prepare_and_execute_statement "SELECT * FROM \"#{schema_name}\".\"#{table_name}\"", options
        }.not_to raise_error
      end
    end
  end
end