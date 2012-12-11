require "spec_helper"

describe GpdbTable do
  let(:table) { datasets(:table) }
  let(:account) { table.schema.database.gpdb_instance.owner_account }

  describe "#analyze" do
    it "generates the correct sql" do
      fake_connection = Object.new
      mock(fake_connection).exec_query("analyze \"#{table.schema.name}\".\"#{table.name}\"")
      stub(table.schema).with_gpdb_connection(account) { |_, block| block.call(fake_connection) }

      table.analyze(account)
    end

    context "when an error happens" do
      before do
        fake_connection = Object.new
        mock(fake_connection).exec_query.with_any_args { raise sql_exception }
        stub(table.schema).with_gpdb_connection(account) { |_, block| block.call(fake_connection) }
      end

      context "when the dataset is stale" do
        let(:sql_exception) { ActiveRecord::StatementInvalid.new('ActiveRecord::JDBCError: ERROR: relation "public.deleted1" does not exist: analyze "public"."deleted1"') }

        it 'raises a ActiveRecord::JDBCError' do
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
