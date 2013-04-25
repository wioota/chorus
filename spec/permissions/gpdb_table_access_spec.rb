require 'spec_helper'

describe GpdbTableAccess do
  let(:context) { Object.new }
  let(:access) { GpdbTableAccess.new(context)}
  let(:gpdb_table) { datasets(:table) }

  before do
    stub(context).current_user { user }
  end

  describe "#show?" do
    context "if the user is an admin" do
      let(:user) { users(:admin) }

      it "allows access" do
        access.can?(:show, gpdb_table).should be_true
      end
    end

    context "if the user has access to the table's data source" do
      let(:user) { users(:the_collaborator) }

      it "allows access" do
        access.can?(:show, gpdb_table).should be_true
      end
    end

    context "if the user does not have access to the table's data source" do
      let(:user) { users(:the_collaborator) }

      before do
        any_instance_of(GpdbDataSourceAccess) do |instance|
          stub(instance).can? :show, gpdb_table.data_source { false }
        end
      end

      it "prevents access" do
        access.can?(:show, gpdb_table).should be_false
      end
    end
  end
end