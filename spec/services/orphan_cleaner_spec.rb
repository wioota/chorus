require 'spec_helper'

describe OrphanCleaner do
  describe "clean" do
    before do
      any_instance_of(GreenplumConnection) do |connection|
        stub(connection).running?
      end
    end

    it "removes orphaned hdfs entries" do
      hdfs_data_source = hdfs_data_sources(:hadoop)
      entries = hdfs_data_source.hdfs_entries
      entries.count.should > 0
      hdfs_data_source.destroy
      OrphanCleaner.clean
      entries.count.should == 0
    end

    context "for gpdb data source" do
      let(:data_source) { data_sources(:owners) }

      it "removes orphaned gpdb databases" do
        databases = data_source.databases
        data_source.destroy
        databases.count.should > 0
        OrphanCleaner.clean
        databases.count.should == 0
      end

      it "removes orphaned schemas" do
        schema_ids = data_source.schema_ids
        data_source.destroy
        data_source.databases.update_all(:deleted_at => Time.now)
        schema_ids.length.should > 0
        OrphanCleaner.clean
        Schema.where(:id => schema_ids).count.should == 0
      end

      it "removes orphaned datasets" do
        dataset_ids = data_source.dataset_ids
        data_source.destroy
        data_source.schemas.update_all(:deleted_at => Time.now)
        dataset_ids.length.should > 0
        OrphanCleaner.clean
        Dataset.where(:id => dataset_ids).count.should == 0
      end
    end

    context "for oracle source" do
      let(:data_source) { data_sources(:oracle) }

      it "removes orphaned schemas" do
        schemas = data_source.schemas
        data_source.destroy
        schemas.length.should > 0
        OrphanCleaner.clean
        schemas.count.should == 0
      end

      it "removes orphaned datasets" do
        dataset_ids = data_source.dataset_ids
        data_source.destroy
        data_source.schemas.update_all(:deleted_at => Time.now)
        dataset_ids.length.should > 0
        OrphanCleaner.clean
        Dataset.where(:id => dataset_ids).count.should == 0
      end
    end
  end
end