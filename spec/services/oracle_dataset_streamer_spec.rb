require 'spec_helper'

describe OracleDatasetStreamer, :oracle_integration do
  before(:all) do
    require Rails.root + 'lib/libraries/ojdbc6.jar'
  end

  describe "#enum" do
    let(:streamer) {
      OracleDatasetStreamer.new()
    }

    let(:table_data) { ["AK,ALASKA\n",
                        "AL,ALABAMA\n",
                        "AR,ARKANSAS\n",
                        "AZ,ARIZONA\n"]
    }

    let(:db_url) { 'jdbc:oracle:thin:system/oracle@//chorus-oracle:1521/orcl' }

    it "returns an Enumerator that yields every row of the table" do
      enumerator = streamer.enum

      4.times do
        table_data.delete(enumerator.next).should_not be_nil
      end

      count_enumerator(enumerator).should == 47
    end

    it "turns off auto commit and sets fetch size" do
      stub.proxy(Sequel).connect(db_url, :test => true) do |connection|
        connection.synchronize(:default) do |jdbc_conn|
          mock(jdbc_conn).set_auto_commit(false)
          stub.proxy(jdbc_conn).create_statement do |statement|
            mock.proxy(statement).set_fetch_size(anything) do |set_value|
              set_value.should > 0
            end
          end

          stub(connection).synchronize.with_no_args.yields(jdbc_conn)
        end
        connection
      end

      count_enumerator(streamer.enum)
    end
  end

  def count_enumerator(enum)
    count = 0

    begin
      while true
        enum.next
        count += 1
      end
    rescue StopIteration
    end

    count
  end
end