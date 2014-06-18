require 'spec_helper'

describe HdfsImport do

  describe 'validations' do
    it { should belong_to(:user) }
    it { should belong_to(:hdfs_entry) }
    it { should belong_to(:upload) }
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:hdfs_entry) }
    it { should validate_presence_of(:upload) }

    let(:hdfs_entry) { hdfs_entries(:hdfs_file) }
    let(:hdfs_directory) { hdfs_entries(:directory) }

    it 'requires the hdfs entry to be a directory' do
      invalid = FactoryGirl.build(:hdfs_import, :hdfs_entry => hdfs_entry)
      invalid.should have_error_on(:hdfs_entry, :DIRECTORY_REQUIRED)

      FactoryGirl.build(:hdfs_import, :hdfs_entry => hdfs_directory).should be_valid
    end
  end

  describe '#destination_file_name' do
    let(:import) { FactoryGirl.create(:hdfs_import, :hdfs_entry => hdfs_entries(:directory), :file_name => file_name) }

    context 'when it has a file_name' do
      let(:file_name) { '123.csv' }

      it 'returns that file_name' do
        import.destination_file_name.should == '123.csv'
      end
    end

    context 'when it does not have a file_name' do
      let(:file_name) { nil }

      it 'returns the file name of the upload' do
        import.destination_file_name.should == import.upload.contents_file_name
      end
    end
  end

end
