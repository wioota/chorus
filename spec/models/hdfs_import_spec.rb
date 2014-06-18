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
end
