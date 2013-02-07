require 'spec_helper'

describe GpdbDataset do
  let(:gpdb_data_source) { data_sources(:owners) }
  let(:account) { gpdb_data_source.owner_account }
  let(:schema) { schemas(:default) }
  let(:other_schema) { schemas(:other_schema) }
  let(:dataset) { datasets(:table) }
  let(:source_table) { datasets(:source_table) }
  let(:dataset_view) { datasets(:view) }

  describe "associations" do
    it { should have_many :associated_datasets }
    it { should have_many :bound_workspaces }

  end

  context ".total_entries" do
    before do
      connection = Object.new
      stub(schema).connect_with(account) { connection }
      stub(connection).datasets_count { 3 }
    end

    it "returns the number of total entries" do
      GpdbDataset.total_entries(account, schema).should == 3
    end
  end

  describe ".add_metadata!(dataset, account)" do
    let(:metadata_sql) { GpdbDataset::Query.new(schema).metadata_for_dataset([dataset.name]).to_sql }
    let(:partition_data_sql) { GpdbDataset::Query.new(schema).partition_data_for_dataset([dataset.name]).to_sql }

    before do
      found_datasets = [
          {:type => "r", :name => dataset.name, :master_table => 't'}
      ]
      connection = Object.new
      stub(schema).connect_with(account) { connection }
      mock(connection).datasets({}).at_least(1) { found_datasets.map(&:clone) }

      stub_gpdb(account,
                metadata_sql => [
                    {
                        'name' => dataset.name,
                        'description' => 'table1 is cool',
                        'definition' => nil,
                        'column_count' => '3',
                        'row_count' => '5',
                        'table_type' => 'BASE_TABLE',
                        'last_analyzed' => '2012-06-06 23:02:42.40264+00',
                        'disk_size' => '500',
                        'partition_count' => '6'
                    }
                ],

                partition_data_sql => [
                    {
                        'disk_size' => '120000'
                    }
                ]
      )
    end

    it "fills in the 'description' attribute of each db object in the relation" do
      schema.refresh_datasets(account)
      dataset.add_metadata!(account)

      dataset.statistics.description.should == "table1 is cool"
      dataset.statistics.definition.should be_nil
      dataset.statistics.column_count.should == 3
      dataset.statistics.row_count.should == 5
      dataset.statistics.table_type.should == 'BASE_TABLE'
      dataset.statistics.last_analyzed.to_s.should == "2012-06-06 23:02:42 UTC"
      dataset.statistics.disk_size.should == 120500
      dataset.statistics.partition_count.should == 6
    end
  end

  describe ".add_metadata! for a view" do
    let(:metadata_sql) { GpdbDataset::Query.new(schema).metadata_for_dataset([dataset_view.name]).to_sql }
    before do
      found_datasets = [
          {'type' => "v", "name" => dataset_view.name}
      ]
      connection = Object.new
      stub(schema).connect_with(account) { connection }
      mock(connection).datasets({}).at_least(1) { found_datasets.map(&:clone) }

      stub_gpdb(account,
                metadata_sql => [
                    {
                        'name' => dataset_view.name,
                        'description' => 'view1 is super cool',
                        'definition' => 'SELECT * FROM users;',
                        'column_count' => '3',
                        'last_analyzed' => '2012-06-06 23:02:42.40264+00',
                        'disk_size' => '0',
                    }
                ]
      )
    end

    it "fills in the 'description' attribute of each db object in the relation" do
      schema.refresh_datasets(account)
      dataset_view.add_metadata!(account)

      dataset_view.statistics.description.should == "view1 is super cool"
      dataset_view.statistics.definition.should == 'SELECT * FROM users;'
      dataset_view.statistics.column_count.should == 3
      dataset_view.statistics.last_analyzed.to_s.should == "2012-06-06 23:02:42 UTC"
      dataset_view.statistics.disk_size == 0
    end
  end

  describe "search fields" do
    let(:dataset) { datasets(:searchquery_table) }
    it "indexes text fields" do
      Dataset.should have_searchable_field :name
      Dataset.should have_searchable_field :table_description
      Dataset.should have_searchable_field :database_name
      Dataset.should have_searchable_field :schema_name
      Dataset.should have_searchable_field :column_name
      Dataset.should have_searchable_field :column_description
    end

    it "returns the schema name for schema_name" do
      dataset.schema_name.should == dataset.schema.name
    end

    it "returns the database name for database_name" do
      dataset.database_name.should == dataset.schema.database.name
    end

    it "un-indexes the dataset when it becomes stale" do
      mock(dataset).solr_remove_from_index
      dataset.stale_at = Time.current
      dataset.save!
    end

    it "re-indexes the dataset when it becomes un stale" do
      dataset.stale_at = Time.current
      dataset.save!
      mock(dataset).solr_index
      dataset.stale_at = nil
      dataset.save!
    end

    describe "workspace_ids" do
      let(:workspace) { workspaces(:search_public) }
      let(:chorus_view) { datasets(:searchquery_chorus_view) }

      it "includes the id of all associated workspaces" do
        chorus_view.found_in_workspace_id.should include(workspace.id)
      end

      it "includes the id of all workspaces that include the dataset through a sandbox" do
        dataset.found_in_workspace_id.should include(workspace.id)
      end
    end
  end

  describe "#all_rows_sql" do
    it "returns the correct sql" do
      dataset = datasets(:table)
      dataset.all_rows_sql().strip.should == %Q{SELECT * FROM "#{dataset.name}"}
    end

    context "with a limit" do
      it "uses the limit" do
        dataset = datasets(:table)
        dataset.all_rows_sql(10).should match "LIMIT 10"
      end
    end
  end

  describe "#destroy" do
    let(:dataset) { datasets(:table) }

    it "should not delete the dataset entry" do
      dataset.destroy
      expect {
        dataset.reload
      }.to_not raise_error(Exception)
    end

    it "should update the deleted_at field" do
      dataset.destroy
      dataset.reload.deleted_at.should_not be_nil
    end

    it "destroys dependent import_schedules" do
      schedules = dataset.import_schedules
      schedules.length.should > 0

      dataset.destroy
      schedules.each do |schedule|
        ImportSchedule.find_by_id(schedule.id).should be_nil
      end
    end

    it "destroys dependent tableau_workbook_publications" do
      tableau_publication = tableau_workbook_publications(:default)
      dataset = tableau_publication.dataset

      dataset.destroy
      TableauWorkbookPublication.find_by_id(tableau_publication.id).should be_nil
    end

    it "destroys dependent associated_datasets" do
      associated_dataset = AssociatedDataset.first
      dataset = associated_dataset.dataset

      dataset.destroy
      AssociatedDataset.find_by_id(associated_dataset.id).should be_nil
    end
  end
end

describe GpdbDataset::Query, :greenplum_integration do
  let(:account) { InstanceIntegration.real_gpdb_account }
  let(:database) { GpdbDatabase.find_by_name_and_data_source_id(InstanceIntegration.database_name, InstanceIntegration.real_gpdb_data_source) }
  let(:schema) { database.schemas.find_by_name('test_schema') }

  subject do
    GpdbDataset::Query.new(schema)
  end

  let(:rows) do
    schema.connect_with(account).fetch(sql)
  end

  describe "queries" do
    context "when table is not in 'public' schema" do
      let(:sql) { "SELECT * FROM base_table1" }

      it "works" do
        lambda { rows }.should_not raise_error
      end
    end

    context "when 'public' schema does not exist" do
      let(:database_name) { "#{InstanceIntegration.database_name}_priv" }
      let(:database) { GpdbDatabase.find_by_name_and_data_source_id(database_name, InstanceIntegration.real_gpdb_data_source) }
      let(:schema) { database.schemas.find_by_name('non_public_schema') }
      let(:sql) { "SELECT * FROM non_public_base_table1" }

      it "works" do
        lambda { rows }.should_not raise_error
      end
    end
  end

  describe "#metadata_for_dataset" do
    context "Base table" do
      let(:sql) { subject.metadata_for_dataset("base_table1").to_sql }

      it "returns a query whose result for a base table is correct" do
        row = rows.first

        row[:name].should == "base_table1"
        row[:description].should == "comment on base_table1"
        row[:definition].should be_nil
        row[:column_count].should == 5
        row[:row_count].should == 9
        row[:table_type].should == "BASE_TABLE"
        row[:last_analyzed].should_not be_nil
        row[:disk_size].to_i.should > 0
        row[:partition_count].should == 0
      end
    end

    context "Master table" do
      let(:sql) { subject.metadata_for_dataset("master_table1").to_sql }

      it "returns a query whose result for a master table is correct" do
        row = rows.first

        row[:name].should == 'master_table1'
        row[:description].should == 'comment on master_table1'
        row[:definition].should be_nil
        row[:column_count].should == 2
        row[:row_count].should == 0 # will always be zero for a master table
        row[:table_type].should == 'MASTER_TABLE'
        row[:last_analyzed].should_not be_nil
        row[:disk_size].should == '0'
        row[:partition_count].should == 7
      end
    end

    context "External table" do
      let(:sql) { subject.metadata_for_dataset("external_web_table1").to_sql }

      it "returns a query whose result for an external table is correct" do
        row = rows.first

        row[:name].should == 'external_web_table1'
        row[:description].should be_nil
        row[:definition].should be_nil
        row[:column_count].should == 5
        row[:row_count].should == 0 # will always be zero for an external table
        row[:table_type].should == 'EXT_TABLE'
        row[:last_analyzed].should_not be_nil
        row[:disk_size].should == '0'
        row[:partition_count].should == 0
      end
    end

    context "View" do
      let(:sql) { subject.metadata_for_dataset("view1").to_sql }

      it "returns a query whose result for a view is correct" do
        row = rows.first
        row[:name].should == 'view1'
        row[:description].should == "comment on view1"
        row[:definition].should == "SELECT base_table1.id, base_table1.column1, base_table1.column2, base_table1.category, base_table1.time_value FROM base_table1;"
        row[:column_count].should == 5
        row[:row_count].should == 0
        row[:disk_size].should == '0'
        row[:partition_count].should == 0
      end
    end
  end

  describe "#dataset_consistent?", :greenplum_integration do
    let(:schema) { GpdbSchema.find_by_name('test_schema') }
    let(:dataset) { schema.datasets.find_by_name('base_table1') }

    context "when tables have same column number, names and types" do
      let(:another_dataset) { schema.datasets.find_by_name('view1') }

      it "says tables are consistent" do
        dataset.dataset_consistent?(another_dataset).should be_true
      end
    end

    context "when tables have same column number and types, but different names" do
      let(:another_dataset) { schema.datasets.find_by_name('different_names_table') }

      it "says tables are not consistent" do
        dataset.dataset_consistent?(another_dataset).should be_false
      end
    end

    context "when tables have same column number and names, but different types" do
      let(:another_dataset) { schema.datasets.find_by_name('different_types_table') }

      it "says tables are not consistent" do
        dataset.dataset_consistent?(another_dataset).should be_false
      end
    end

    context "when tables have different number of columns" do
      let(:another_dataset) { schema.datasets.find_by_name('master_table1') }

      it "says tables are not consistent" do
        dataset.dataset_consistent?(another_dataset).should be_false
      end
    end
  end
end
