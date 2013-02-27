require 'spec_helper'

describe DuplicateSchemaValidator do
  describe ".run" do
    let(:conn) { ActiveRecord::Base.connection }

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
end
