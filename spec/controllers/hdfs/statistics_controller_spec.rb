require "spec_helper"

describe Hdfs::StatisticsController do
  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
  let(:entry) { hdfs_entries(:hdfs_file) }

  before do
    log_in users(:owner)
  end

  describe "show" do

    let(:statistics) {
      OpenStruct.new(
        'owner' => 'the_boss',
        'group' => 'the_group',
        'modified_at' => '2012-06-06 23:02:42',
        'accessed_at' => '2012-06-06 23:02:42',
        'size' => 1234098,
        'block_size' => 128,
        'permissions' => 'rw-r--r--',
        'replication' => 3
      )
    }

    before do
      mock(HdfsEntry).statistics(entry.path.chomp('/'), entry.hdfs_data_source) { HdfsEntryStatistics.new statistics }
    end

    it "should retrieve the statistics for an entry" do
      get :show, :hdfs_data_source_id => hdfs_data_source.id, :file_id => entry.id

      response.code.should == '200'
      decoded_response.owner.should == 'the_boss'
      decoded_response.group.should == 'the_group'
      decoded_response.file_size.should == 1234098
    end

    generate_fixture "hdfsEntryStatistics.json" do
      get :show, :hdfs_data_source_id => hdfs_data_source.id, :file_id => entry.id
    end

  end

end
