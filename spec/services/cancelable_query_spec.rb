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

    shared_examples_for :a_cancelable_query do
      it "cancels the query" do
        query_thread = Thread.new(check_id, connection_pool) do |check_id, connection_pool|
          with_connection connection_pool do |conn|
            expect {
              CancelableQuery.new(conn, check_id).execute("SELECT pg_sleep(15)")
            }.to raise_error(CancelableQuery::QueryError)
          end
        end

        with_connection connection_pool do |cancel_connection|
          wait_until { get_running_queries_by_check_id(cancel_connection).present? }
          CancelableQuery.new(cancel_connection, check_id).cancel
          wait_until { get_running_queries_by_check_id(cancel_connection).nil? }
        end

        query_thread.join
      end

      def get_running_queries_by_check_id(conn)
        query = "select query from pg_stat_activity;"
        conn.select_all(query).find { |row| row["query"].include? check_id }
      rescue ActiveRecord::StatementInvalid
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

      def with_connection(connection_pool)
        connection = connection_pool.checkout
        yield connection
      ensure
        connection_pool.checkin connection
      end
    end

    # TODO: Work out why this pollutes the tests.
    #it_behaves_like :a_cancelable_query do
    #  let(:connection_pool) {
    #    ActiveRecordConnectionPool.new
    #  }
    #end

    class ActiveRecordConnectionPool
      def initialize
        @pool = ActiveRecord::Base.connection_handler.retrieve_connection_pool(ActiveRecord::Base)
      end

      def checkout
        @pool.checkout
      end

      def checkin(connection)
        @pool.checkin connection
      end
    end

    describe "with a real database connection", :database_integration => true do
      let(:account) { InstanceIntegration.real_gpdb_account }

      it_behaves_like :a_cancelable_query do
        let(:connection_pool) {
          GpdbConnectionPool.new(account)
        }
      end

      class GpdbConnectionPool
        def initialize(account)
          @account = account
        end

        def checkout
          gpdb_instance = @account.gpdb_instance
          Gpdb::ConnectionBuilder.connect!(gpdb_instance, @account)
        end

        def checkin(connection)
          connection.disconnect!
        end
      end
    end
  end
end
