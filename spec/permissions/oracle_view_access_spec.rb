require 'spec_helper'

describe OracleViewAccess do
  let(:context) { Object.new }
  let(:access) { OracleViewAccess.new(context)}
  let(:view) { datasets(:oracle_view) }

  before do
    stub(context).current_user { user }
  end

  describe "#show?" do
    context "if the user is an admin" do
      let(:user) { users(:admin) }

      it "allows access" do
        access.can?(:show, view).should be_true
      end
    end

    context "if the user has access to the view's instance" do
      let(:user) { users(:the_collaborator) }

      it "allows access" do
        access.can?(:show, view).should be_true
      end
    end

    context "if the user does not have access to the view's instance" do
      let(:user) { users(:the_collaborator) }

      before do
        any_instance_of(OracleDataSourceAccess) do |instance|
          stub(instance).can? :show, view.data_source { false }
        end
      end

      it "prevents access" do
        access.can?(:show, view).should be_false
      end
    end
  end
end