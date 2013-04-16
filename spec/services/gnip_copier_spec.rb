require 'spec_helper'

describe GnipCopier do
  let(:destination_schema) { schemas(:default) }
  let(:destination_table_name) { 'table of my destiny' }
  let(:user) { "gnip copier guy" }
  let(:connection) { Object.new }
  let(:gnip_data_source) { gnip_data_sources(:default) }
  let(:copier) do
    GnipCopier.new(
        {
            :source => gnip_data_source,
            :destination_schema => destination_schema,
            :destination_table_name => destination_table_name,
            :user => user
        }
    )
  end

  before do
    stub(destination_schema).connect_as(user) { connection }
  end

  describe 'initialize_destination_table' do
    before do
      stub(connection).table_exists?(destination_table_name) { table_exists }
    end

    context "when the table doesn't exist" do
      let(:table_exists) { false }

      it "should create the table with the right columns" do
        csv_result = GnipCsvResult.new('')
        table_description = csv_result.column_names.zip(csv_result.types).map { |name, type| "#{name} #{type}" }.join(", ")
        mock(connection).create_table(destination_table_name, table_description, 'DISTRIBUTED RANDOMLY')
        copier.initialize_destination_table
      end
    end
  end

  describe 'run' do
    before do
      stub(ChorusGnip).from_stream.with_any_args do
        stream = Object.new
        stub(stream).fetch { %w(foo bar) }
        stub(stream).to_result_in_batches(%w(foo)) { foo_csv }
        stub(stream).to_result_in_batches(%w(bar)) { bar_csv }
      end
    end

    let(:foo_csv) { 'hi,bye' }
    let(:bar_csv) { 'yo,dawg' }

    it 'copies the data into the destination table' do
      first_time = true
      mock(connection).copy_csv(is_a(java.io.StringReader), destination_table_name, GnipCsvResult.new('').column_names, ',', false).times(2) do |reader|
        buffer = java.io.BufferedReader.new(reader)
        if first_time
          buffer.read_line.should == foo_csv
          first_time = false
        else
          buffer.read_line.should == bar_csv
        end
      end
      copier.run
    end
  end
end