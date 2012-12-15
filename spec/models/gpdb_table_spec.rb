require "spec_helper"

describe GpdbTable do
  let(:table) { datasets(:table) }
  let(:account) { table.gpdb_instance.owner_account }
  let(:connection) { Object.new }

  before do
    stub(table.schema).connect_with(account) { connection }
  end

  describe "#analyze" do
    it "calls out to the connection" do
      mock(connection).analyze_table(table.name)
      table.analyze(account)
    end

    context "when an error happens" do
      before do
        stub(connection).analyze_table(table.name) { raise sql_exception }
      end

      context "when the dataset is does not exist" do
        let(:sql_exception) { Sequel::DatabaseError.new('ERROR: relation "public.deleted1" does not exist: analyze "public"."deleted1"') }

        it "raises a ActiveRecord::StatementInvalid" do
          expect {
            table.analyze(account)
          }.to raise_error(ActiveRecord::StatementInvalid, 'Dataset ("public.deleted1") does not exist anymore')
        end
      end

      context "when an unknown error occurs" do
        let(:sql_exception) { ActiveRecord::JDBCError.new('something bad happened') }

        it "reraises the exception" do
          expect {
            table.analyze(account)
          }.to raise_error(ActiveRecord::JDBCError, 'something bad happened')
        end
      end
    end
  end
end
