require 'spec_helper'

describe OrphanCleaner do
  describe "clean" do
    it "removes orphaned hdfs entries" do
      hdfs_data_source = hdfs_data_sources(:hadoop)
      entries = hdfs_data_source.hdfs_entries
      entries.count.should > 0
      hdfs_data_source.destroy
      OrphanCleaner.clean
      entries.count.should == 0
    end
  end
end