require 'spec_helper'

describe Schema do
  describe ".find_and_verify_in_source" do
    let(:schema) { schemas(:public) }
    let(:database) { schema.database }
    let(:user) { users(:owner) }
    let(:connection) { Object.new }

    before do
      mock(database).connect_as(anything) { connection }
      stub(Schema).find(schema.id) { schema }
    end

    context "when it exists in the source database" do
      before do
        mock(connection).schema_exists?(anything) { true }
      end

      it "returns the schema" do
        described_class.find_and_verify_in_source(schema.id, user).should == schema
      end
    end

    context "when it does not exist in the source database" do
      before do
        mock(connection).schema_exists?(anything) { false }
      end

      it "should raise ActiveRecord::RecordNotFound exception" do
        expect {
          described_class.find_and_verify_in_source(schema.id, user)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end