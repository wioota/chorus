require "spec_helper"

describe DataSourceAccountAccess do
  let(:data_source_account) { data_source.accounts.build(:owner => current_user) }
  let(:owner) { data_source.owner }
  let(:data_source_account_access) {
    stub(controller = Object.new).current_user { current_user }
    DataSourceAccountAccess.new(controller)
  }

  describe "update?" do
    context "for a shared data_source" do
      let(:data_source) { data_sources(:shared) }

      context "for the owner" do
        let(:current_user) { data_source.owner }

        it "is allowed" do
          data_source_account_access.can?(:update, data_source_account).should be_true
        end
      end

      context "for others" do
        let(:current_user) { users(:no_collaborators) }

        it "is not allowed" do
          data_source_account_access.can?(:update, data_source_account).should be_false
        end
      end
    end

    context "for a data_source with individual accounts" do
      let(:data_source) { data_sources(:default) }
      let(:current_user) { users(:default) }

      it "is allowed" do
        data_source_account_access.can?(:update, data_source_account).should be_true
      end
    end
  end
end