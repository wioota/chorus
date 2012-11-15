require 'spec_helper'

describe GpdbViewAccess do
  let(:context) { Object.new }
  let(:access) { GpdbViewAccess.new(context)}
  let(:gpdb_view) { datasets(:view) }

  before do
    stub(context).current_user { user }
  end

  describe "#show?" do
    context "if the user is an admin" do
      let(:user) { users(:admin) }

      it "allows access" do
        access.can?(:show, gpdb_view).should be_true
      end
    end

    context "if the user has access to the view's instance" do
      let(:user) { users(:the_collaborator) }

      it "allows access" do
        access.can?(:show, gpdb_view).should be_true
      end
    end

    context "if the user does not have access to the view's instance" do
      let(:user) { users(:the_collaborator) }

      before do
        any_instance_of(GpdbInstanceAccess) do |instance|
          stub(instance).can? :show, gpdb_view.gpdb_instance { false }
        end
      end

      it "prevents access" do
        access.can?(:show, gpdb_view).should be_false
      end
    end
  end
end