require 'spec_helper'

describe ColumnController do
  ignore_authorization!

  before do
    log_in user
  end

  context "#index" do
    context "with mock data" do
      let(:user) { users(:no_collaborators) }
      let(:table) { datasets(:table) }

      before do
        fake_account = Object.new
        stub(subject).account_for_current_user(table) { fake_account }
        stub(GpdbColumn).columns_for(fake_account, table) do
          [
              GpdbColumn.new(:name => 'email', :data_type => 'varchar(255)', :description => 'it must be present'),
              GpdbColumn.new(:name => 'age', :data_type => 'integer', :description => 'nothing'),
          ]
        end
      end

      it "should check for permissions" do
        mock(subject).authorize! :show_contents, table.data_source
        get :index, :dataset_id => table.to_param
      end

      it_behaves_like "a paginated list" do
        let(:params) {{ :dataset_id => table.to_param }}
      end

      it "should retrieve column for a table" do
        get :index, :dataset_id => table.to_param

        response.code.should == "200"
        decoded_response.length.should == 2
      end
    end

    context "with real data", :greenplum_integration do
      let(:account) { InstanceIntegration.real_gpdb_account }
      let(:user) { account.owner }
      let(:database) { GpdbDatabase.find_by_name_and_data_source_id(InstanceIntegration.database_name, InstanceIntegration.real_gpdb_data_source) }
      let(:dataset) {database.find_dataset_in_schema('base_table1', 'test_schema')}

      before do
        dataset.analyze(account)
      end

      generate_fixture "databaseColumnSet.json" do
        get :index, :dataset_id => dataset.to_param
      end

      it "generates a column fixture", :fixture do
        get :index, :dataset_id => dataset.to_param
        save_fixture "databaseColumn.json", { :response => response.decoded_body["response"].first }
      end
    end
  end
end
