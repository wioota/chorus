require 'legacy_migration_spec_helper'

describe HdfsEntryMigrator do
  describe ".migrate" do
    it "should migrate the hdfs references found in the edc_comment table to the new database" do
      rows = Legacy.connection.select_all("
         SELECT DISTINCT normalize_key(object_id) AS entity_id
          FROM edc_activity_stream_object
          WHERE entity_type = 'hdfs'
      ").each do |legacy_row|
        legacy_hadoop_instance_id, path = legacy_row["entity_id"].split("|")
        hadoop_instance = HadoopInstance.find_by_legacy_id!(legacy_hadoop_instance_id)
        entry = HdfsEntry.find_by_hadoop_instance_id_and_path(hadoop_instance.id, path)
        entry.should_not be_nil
        entry.legacy_id.should == legacy_row["entity_id"]
        entry.parent.should_not be_nil
        entry.parent.is_directory.should be_true
      end
      rows.count.should > 0
      HdfsEntry.count.should > rows.count # creates some extra directories
    end

    it "is idempotent" do
      expect {
        HdfsEntryMigrator.migrate
      }.not_to change(HdfsEntry.unscoped, :count)
    end
  end
end