require 'spec_helper'

resource 'Jdbc HiveData sources' do
  let(:owner) { users(:owner) }
  let(:jdbc_hive_data_source) { data_sources(:owners) }

  before do
    log_in owner
    any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {true} }
  end

  post '/jdbc_hive_data_sources' do
    true
    #parameter :name, 'Name to show Chorus users for data source'
    #parameter :description, 'Description of data source'
    #parameter :host, 'Host IP or address of data source'
    #parameter :db_username, 'Username for connection to data source'
    #parameter :db_password, 'Password for connection to data source'
    #parameter :hive, 'Is hive'
    #parameter :hive_kerberos, 'Is Kerberos enabled'
    #parameter :hive_hadoop_version, 'Hive Hadoop version'
    #parameter :hive_kerberos_principal, 'Hive principal'
    #parameter :hive_kerberos_keytab_location, 'Hive Keytab Location'
    #parameter :shared, 'true to allow anyone to connect using these credentials, false to require individuals to enter their own credentials'
    #
    #let(:name) { 'Sesame_Street' }
    #let(:description) { 'Can you tell me how to get...' }
    #let(:host) { 'sesame.street.local' }
    #let(:db_username) { 'big' }
    #let(:db_password) { 'bird_yellow' }
    #let(:hive) { true }
    #let(:hive_hadoop_version) { 'Cloudera CDH5' }
    #let(:hive_kerberos_principal) { 'xxxx' }
    #let(:hive_kerberos_keytab_location) { 'xxxx' }
    #let(:hive_kerberos) { false }
    #let(:shared) { true }
    #
    #required_parameters :name, :host, :hive, :hive_hadoop_version, :hive_kerberos
    #
    #example_request 'Register a data source' do
    #  status.should == 201
    #end
  end

  get "/jdbc_hive_data_sources" do
    true
    #parameter :entity_type, "The specific type of data sources to return. Returns all types if blank"
    #parameter :all, "true to return all data sources, rather than the default which only includes data sources the user has access to"
    #pagination
    #
    #let(:hive) { true }
    #
    #example_request "Get a list of registered data sources" do
    #  status.should == 200
    #end
  end

  get "/jdbc_hive_data_sources/:id" do
    true
    #parameter :id, "Data sources id"
    #let(:id) { jdbc_hive_data_source.to_param }
    #
    #example_request "Get a registered data source" do
    #  status.should == 200
    #end
  end

  put "/jdbc_hive_data_sources/:id" do
    true
    #parameter :id, "Data source id"
    #parameter :name, "Name to show Chorus users for data source"
    #parameter :description, "Description of data source"
    #parameter :host, "Host IP or address of data source"
    #parameter :hive, 'Is hive'
    #parameter :hive_kerberos, 'Is Kerberos enabled'
    #parameter :hive_hadoop_version, 'Hive Hadoop version'
    #parameter :hive_kerberos_principal, 'Hive principal'
    #parameter :hive_kerberos_keytabl_location, 'Hive Keytab Location'
    #parameter :db_name, "Database on data source to use for initial connection (usually 'postgres')"
    #
    #let(:id) { owned_data_source.to_param }
    #let(:name) { "Sesame_Street" }
    #let(:description) { "Can you tell me how to get..." }
    #let(:host) { "sesame.street.local" }
    #let(:port) { "5432" }
    #let(:db_name) { "postgres" }
    #
    #example_request "Update data source details" do
    #  status.should == 200
    #end
  end

  post "/jdbc_hive_data_sources/:jdbc_hive_data_source_id/imports" do
    true
    #example_request "Update data source details" do
    #  status.should == 200
    #end
  end

  delete "/jdbc_hive_data_sources/:id" do
    true
    #parameter :id, "JDBC Hive Data source id"
    #
    #let(:id) { owned_data_source.to_param }
    #before do
    #  any_instance_of(GreenplumConnection) do |connection|
    #    stub(connection).running?
    #  end
    #end
    #
    #example_request "Delete a data source" do
    #  status.should == 200
    #end
  end


end
