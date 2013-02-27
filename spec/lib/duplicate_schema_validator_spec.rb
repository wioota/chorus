require 'spec_helper'

describe DuplicateSchemaValidator do
  let(:conn) { ActiveRecord::Base.connection }

  describe ".run" do
    context "when the unique index exists" do
      before do
        unless conn.index_exists? :schemas, [:parent_id, :parent_type, :name], :unique => true
          conn.add_index :schemas, [:parent_id, :parent_type, :name], :unique => true
        end
      end

      it "returns true" do
        DuplicateSchemaValidator.run.should be_true
      end
    end

    context "when the unique index does not exist" do
      before do
        if conn.index_exists? :schemas, [:parent_id, :parent_type, :name], :unique => true
          conn.remove_index :schemas, [:parent_id, :parent_type, :name]
        end
      end

      context "when there are duplicate schema names" do
        before do
          datasource = data_sources(:oracle)
          2.times do
            schema = OracleSchema.new
            schema.name = "duplicate_schema"
            schema.parent = datasource
            schema.save!(:validate => false)
          end
        end

        it "returns false" do
          DuplicateSchemaValidator.run.should be_false
        end
      end

      context "when there are no duplicate schema names" do
        it "returns true" do
          DuplicateSchemaValidator.run.should be_true
        end
      end
    end

  end

  describe ".run_and_fix" do
    context "when the unique index exists" do
      before do
        unless conn.index_exists? :schemas, [:parent_id, :parent_type, :name], :unique => true
          conn.add_index :schemas, [:parent_id, :parent_type, :name], :unique => true
        end
      end

      it "returns true" do
        DuplicateSchemaValidator.run_and_fix.should be_true
      end
    end

    context "when the unique index does not exist" do
      before do
        if conn.index_exists? :schemas, [:parent_id, :parent_type, :name], :unique => true
          conn.remove_index :schemas, [:parent_id, :parent_type, :name]
        end
      end

      context "when there are no duplicate schemas" do
        it "returns true" do
          DuplicateSchemaValidator.run_and_fix.should be_true
        end
      end

      context "when there are duplicate schemas" do
        let(:database) { gpdb_databases(:default) }
        let(:duplicate_schemas_in_database) {
          Schema.where(
              :name => "duplicate_schema",
              :parent_id => database.id,
              :parent_type => "GpdbDatabase",
              :deleted_at => nil
          )
        }

        let!(:duplicate_schema_objects) {
          Array.new(2) do
            schema = GpdbSchema.new
            schema.name = "duplicate_schema"
            schema.parent = database
            schema.save!(:validate => false)
            schema
          end
        }

        it "returns true" do
          DuplicateSchemaValidator.run_and_fix.should be_true
        end

        it "removes the duplicate schemas" do
          DuplicateSchemaValidator.run_and_fix
          duplicate_schemas_in_database.count.should eq(1)
        end

        it "links workfiles to the remaining schemas" do
          workfile1 = FactoryGirl.create(:chorus_workfile, :execution_schema => duplicate_schema_objects[0])
          workfile2 = FactoryGirl.create(:chorus_workfile, :execution_schema => duplicate_schema_objects[1])

          DuplicateSchemaValidator.run_and_fix

          workfile1.reload.execution_schema.should eq(duplicate_schemas_in_database.first)
          workfile2.reload.execution_schema.should eq(duplicate_schemas_in_database.first)
        end

        it "links workspaces to the remaining schemas" do
          workspace1 = FactoryGirl.create(:workspace, :sandbox => duplicate_schema_objects[0])
          workspace2 = FactoryGirl.create(:workspace, :sandbox => duplicate_schema_objects[1])

          DuplicateSchemaValidator.run_and_fix

          workspace1.reload.sandbox.should eq(duplicate_schemas_in_database.first)
          workspace2.reload.sandbox.should eq(duplicate_schemas_in_database.first)
        end

        it "links chorus views to the remaining schema" do
          chorusview1 = FactoryGirl.create(:chorus_view, :schema => duplicate_schema_objects[0])
          chorusview2 = FactoryGirl.create(:chorus_view, :schema => duplicate_schema_objects[1])

          DuplicateSchemaValidator.run_and_fix

          chorusview1.reload.schema.should eq(duplicate_schemas_in_database.first)
          chorusview2.reload.schema.should eq(duplicate_schemas_in_database.first)
        end
      end
    end
  end
end
