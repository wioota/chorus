shared_examples "a well-behaved database query" do
  let(:db) { Sequel.connect(db_url, db_options) }

  it "returns the expected result and manages its connection" do
    connection.should_not be_connected
    subject.should == expected
    connection.should_not be_connected
    db.disconnect
  end

  it "masks sequel errors" do
    stub(Sequel).connect(anything, anything) do
      raise Sequel::DatabaseError
    end

    expect {
      subject
    }.to raise_error(DataSourceConnection::Error)
  end
end

shared_examples "a data source connection" do
  describe "connect!" do
    context "when a logger is not provided" do
      before do
        options.delete :logger
        db_options.delete :logger
        mock.proxy(Sequel).connect(db_url, db_options.merge(:test => true))
      end

      context "with valid credentials" do
        it "connects successfully passing no logging options" do
          connection.connect!
          connection.should be_connected
        end
      end
    end

    context "when a logger is provided" do
      let(:logger) do
        log = Object.new
        stub(log).debug
        log
      end

      let(:options) {
        {
          :database => database_name,
          :logger => logger
        }
      }

      before do
        mock.proxy(Sequel).connect(db_url, hash_including(:test => true, :sql_log_level => :debug, :logger => logger))
      end

      context "with valid credentials" do
        it "connects successfully passing the proper logging options" do
          connection.connect!
          connection.should be_connected
        end
      end
    end

    context "when credentials are valid" do
      it "does not set invalid credentials on the account" do
        connection.connect!
        account.invalid_credentials?.should be_false
      end
    end

    context "when credentials are invalid" do
      before do
        account.db_username = 'wrong!'
        account.db_password = 'wrong!'
      end

      it "sets invalid_credentials on the account" do
        expect { connection.connect! }.to raise_error(DataSourceConnection::InvalidCredentials) do |exception|
          exception.subject.should == data_source
        end
        account.invalid_credentials?.should be_true
      end

      context "when account is already flagged as invalid" do
        before do
          account.invalid_credentials!
        end

        it "does not attempt to connect, but still throws an INVALID_PASSWORD error" do
          dont_allow(Sequel).connect
          expect { connection.connect! }.to raise_error(DataSourceConnection::InvalidCredentials) do |exception|
            exception.subject.should == data_source
          end
        end
      end

      context "when connection fails for some reason unrelated to invalid credentials" do
        before do
          data_source.port = '8675309'
        end

        it "does not set invalid credentials on the account" do
          expect { connection.connect! }.to raise_error(exception_class)
          account.invalid_credentials?.should be_false
        end
      end
    end
  end

  describe "disconnect" do
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

  describe "with_connection" do
    before do
      mock.proxy(Sequel).connect(db_url, satisfy { |options| options[:test] })
    end

    context "with valid credentials" do
      it "connects for the duration of the given block" do
        expect {
          connection.with_connection do
            connection.should be_connected
            throw :ran_block
          end
        }.to throw_symbol :ran_block
        connection.should_not be_connected
      end

      it "can be nested" do
        connection.with_connection do
          connection.with_connection do
            connection.should be_connected
          end
        end
        connection.should_not be_connected
      end
    end
  end

  describe "fetch" do
    let(:parameters) { {} }
    let(:subject) { connection.fetch(sql) }
    let(:expected) { [{:col1 => 1}] }

    it_should_behave_like "a well-behaved database query"

    context "with SQL parameters" do
      let(:sql) { sql_with_parameter }
      let(:parameters) { {:param => 3} }

      it "succeeds" do
        connection.fetch(sql, parameters).should == [{:col1 => 3}]
      end
    end
  end

  describe "fetch_value" do
    let(:subject) { connection.fetch_value(sql) }
    let(:expected) { 1 }

    it_should_behave_like "a well-behaved database query"

    it "returns nil for an empty set" do
      connection.fetch_value(empty_set_sql).should == nil
    end
  end

  describe "error_type" do
    context "when an Error is created with an error_type" do
      let(:error) { exception_class.new(:ERROR) }
      it "returns the given error_type" do
        error.error_type.should == :ERROR
      end
    end
  end
end
