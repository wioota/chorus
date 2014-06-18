require 'spec_helper'

describe Hdfs::ImportExecutor do
  let(:hdfs_dir) { hdfs_entries(:directory) }
  let(:import) { FactoryGirl.create(:hdfs_import, :hdfs_entry => hdfs_dir) }

  describe '.run' do

    it 'creates an import executor with the specified import and runs it' do
      mock.proxy(described_class).new(import: import)
      any_instance_of(described_class) { |exe| mock(exe).run }
      described_class.run import.id
    end
  end

  describe '#run' do
    let(:exe) { described_class.new :import => import }

    it 'imports the file in the hdfs data source of the hdfs entry' do
      mock.proxy(Hdfs::QueryService).for_data_source(hdfs_dir.hdfs_data_source)
      any_instance_of Hdfs::QueryService do |qs|
        mock(qs).import_data is_a(String), is_a(java.io.FileInputStream)
      end
      exe.run
    end

    context 'when the import succeeds' do
      before do
        any_instance_of(Hdfs::QueryService) { |qs| mock(qs).import_data.with_any_args { true } }
        exe
      end

      it 'destroys the import and upload' do
        expect {
          expect {
            exe.run
          }.to change(HdfsImport, :count).by(-1)
        }.to change(Upload, :count).by(-1)
      end
    end

    context 'when the import fails' do
      before do
        any_instance_of(Hdfs::QueryService) { |qs| mock(qs).import_data.with_any_args { raise } }
        exe
      end

      it 'destroys the import and upload' do
        expect {
          expect {
            exe.run
          }.to change(HdfsImport, :count).by(-1)
        }.to change(Upload, :count).by(-1)
      end
    end

    # context 'real hdfs', :hdfs_integration do
    #
    #
    # end
  end
end
