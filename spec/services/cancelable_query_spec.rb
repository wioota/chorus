require 'spec_helper'
require 'timeout'

describe CancelableQuery do
  let(:connection) { ActiveRecord::Base.connection }
  let(:sql) { "Select 1 as a" }
  let(:check_id) { '0.1234' }
  let(:cancelable_query) { CancelableQuery.new(connection, check_id) }
  let(:driver) { cancelable_query.driver }

  describe ".execute" do
    it "adds a comment with the check_id to the start of the query" do
      mock.proxy(driver).prepare_statement("/*#{check_id}*/#{sql}")
      cancelable_query.execute(sql)
    end

    it "raises QueryError if an error occurs" do
      mock.proxy(driver).prepare_statement("/*#{check_id}*/#{sql}") do |statement|
        mock(statement).execute { raise "error!" }
      end

      expect { cancelable_query.execute(sql) }.to raise_error(MultipleResultsetQuery::QueryError)
    end

    it "returns the query result" do
      result = cancelable_query.execute(sql)
      result.rows[0][0].should == '1'
    end

    it "returns the last set of results when there are multiple" do
      result = cancelable_query.execute("select 1 as a; select 2 as b;")
      result.rows[0][0].should == '2'
    end
  end

  describe "#cancel" do
    let(:check_id) { '54321' }

    describe "with a real database connection", :database_integration => true do
      let(:account) { InstanceIntegration.real_gpdb_account }
      let(:gpdb_instance) { account.instance }

      it "cancels the query" do
        query_thread = Thread.new do
          Gpdb::ConnectionBuilder.connect!(gpdb_instance, account) do |conn|
            expect {
              CancelableQuery.new(conn, check_id).execute("SELECT pg_sleep(15)")
            }.to raise_error(CancelableQuery::QueryError)
          end
        end

        Gpdb::ConnectionBuilder.connect!(gpdb_instance, account) do |cancel_connection|
          wait_until { get_running_queries_by_check_id(cancel_connection).present? }
          CancelableQuery.new(cancel_connection, check_id).cancel
          wait_until { get_running_queries_by_check_id(cancel_connection).nil? }
        end

        query_thread.join
      end

      def get_running_queries_by_check_id(conn)
        query = "select current_query from pg_stat_activity;"
        conn.select_all(query).find { |row| row["current_query"].include? check_id }
      end

      def wait_until
        Timeout::timeout 5.seconds do
          until yield
            sleep 0.1
          end
        end
      end
    end
  end
end
