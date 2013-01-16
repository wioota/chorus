require 'spec_helper'

resource "Greenplum DB: data sources" do
  let(:owner) { users(:owner) }
  let(:owned_data_source) { data_sources(:owners) }

  before do
    log_in owner
    any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {true} }
  end

  post "/data_sources" do
    parameter :name, "Name to show Chorus users for data source"
    parameter :description, "Description of data source"
    parameter :host, "Host IP or address of Greenplum data source"
    parameter :port, "Port of Greenplum data source"
    parameter :maintenance_db, "Database on data source to use for initial connection (usually 'postgres')"
    parameter :db_username, "Username for connection to data source"
    parameter :db_password, "Password for connection to data source"
    parameter :shared, "1 to allow anyone to connect using these credentials, 0 to require individuals to enter their own credentials"

    let(:name) { "Sesame_Street" }
    let(:description) { "Can you tell me how to get..." }
    let(:host) { "sesame.street.local" }
    let(:port) { "5432" }
    let(:maintenance_db) { "postgres" }
    let(:db_username) { "big" }
    let(:db_password) { "bird_yellow" }
    let(:shared) { "1" }

    required_parameters :name, :host, :port, :maintenance_db, :db_username, :db_password

    example_request "Register a Greenplum data source" do
      status.should == 201
    end
  end

  get "/data_sources" do
    parameter :accessible, "1 to limit the list to data sources the current user can access, 0 for all data sources"
    pagination

    let(:accessible) { "1" }

    example_request "Get a list of registered Greenplum data sources" do
      status.should == 200
    end
  end

  get "/data_sources/:id" do
    parameter :id, "Greenplum data sources id"
    let(:id) { owned_data_source.to_param }

    example_request "Get a registered Greenplum data sources" do
      status.should == 200
    end
  end

  put "/data_sources/:id" do
    parameter :id, "Greenplum data sources id"
    parameter :name, "Name to show Chorus users for data source"
    parameter :description, "Description of data source"
    parameter :host, "Host IP or address of Greenplum data source"
    parameter :port, "Port of Greenplum data source"
    parameter :maintenance_db, "Database on data source to use for initial connection (usually 'postgres')"

    let(:id) { owned_data_source.to_param }
    let(:name) { "Sesame_Street" }
    let(:description) { "Can you tell me how to get..." }
    let(:host) { "sesame.street.local" }
    let(:port) { "5432" }
    let(:maintenance_db) { "postgres" }

    example_request "Update data source details" do
      status.should == 200
    end
  end

  get "/data_sources/:data_source_id/workspace_detail" do
    parameter :data_source_id, "Greenplum data source id"

    let(:data_source_id) { owned_data_source.to_param }

    example_request "Get details for workspaces with sandboxes on this data source" do
      status.should == 200
    end
  end
end
