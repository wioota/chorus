require 'spec_helper'

resource 'Jdbc HiveData sources' do
  let(:owner) { users(:owner) }
  let(:jdbc_hive_data_source) { data_sources(:owners) }

  before do
    log_in owner
    any_instance_of(JdbcHiveDataSource) { |ds| stub(ds).valid_db_credentials? {true} }
  end

  post '/jdbc_hive_data_sources' do
    parameter :name, 'Name to show Chorus users for JDBC Hive data source'
    parameter :description, 'Description of data source'
    parameter :host, 'Host IP or address of data source'
    parameter :db_username, 'Username for connection to data source (if non-kerberos)'
    parameter :db_password, 'Password for connection to data source (if non-kerberos)'
    parameter :hive_kerberos, 'Is Kerberos enabled (true or false)'
    parameter :hive_hadoop_version, 'Hive Hadoop version ("Cloudera CDH5", "HortonWorks HDP 2.1", "MapR4")'
    parameter :hive_kerberos_principal, 'Hive principal (only needed if hive_kerberos is set to true)'
    parameter :hive_kerberos_keytab_location, 'Hive Keytab Location (only needed if hive_kerberos is set to true)'
    parameter :shared, 'true to allow anyone to connect using these credentials, false to require individuals to enter their own credentials'

    let(:name) { 'Hive Source' }
    let(:description) { 'Bzzz Bzzz' }
    let(:host) { 'hive.hive' }
    let(:db_username) { 'default' }
    let(:db_password) { 'default' }
    let(:hive) { true }
    let(:hive_hadoop_version) { 'Cloudera CDH5' }
    let(:hive_kerberos_principal) { 'xxxx' }
    let(:hive_kerberos_keytab_location) { 'xxxx' }
    let(:hive_kerberos) { false }
    let(:shared) { true }
    let(:entity_type) { 'jdbc_hive_data_source' }

    required_parameters :name, :host, :hive_hadoop_version, :hive_kerberos, :db_username, :db_password

    example_request 'Register a data source' do
      status.should == 201
    end
  end

  get "/jdbc_hive_data_sources" do
    pagination

    example_request "Get a list of registered JDBC Hive data sources" do
      status.should == 200
    end
  end

  get "/jdbc_hive_data_sources/:id" do
    parameter :id, "JDBC Hive Data sources id"
    let(:id) { jdbc_hive_data_source.to_param }

    example_request "Get a registered JDBC Hive data source" do
      #status.should == 200
    end
  end

  put "/jdbc_hive_data_sources/:id" do
    parameter :id, 'JDBC Hive Data source id'
    parameter :name, 'Name to show Chorus users for JDBC Hive data source'
    parameter :description, 'Description of data source'
    parameter :host, 'Host IP or address of data source'
    parameter :hive_hadoop_version, 'Hive Hadoop version ("Cloudera CDH5", "HortonWorks HDP 2.1", "MapR4")'
    parameter :hive_kerberos_principal, 'Hive principal (only needed if hive_kerberos is set to true)'
    parameter :hive_kerberos_keytab_location, 'Hive Keytab Location (only needed if hive_kerberos is set to true)'

    let(:id) { jdbc_hive_data_source.to_param }
    let(:name) { 'Hive Source' }
    let(:description) { 'Bzzz Bzzz' }
    let(:host) { 'hive.hive' }
    let(:hive) { true }
    let(:hive_hadoop_version) { 'Cloudera CDH5' }
    let(:hive_kerberos_principal) { 'xxxx' }
    let(:hive_kerberos_keytab_location) { 'xxxx' }

    example_request 'Update JDBC Hive data source details' do
      #status.should == 201
    end
  end

  delete "/jdbc_hive_data_sources/:id" do
    parameter :id, "JDBC Hive Data sources id"
    let(:id) { jdbc_hive_data_source.to_param }

    example_request "Delete a JDBC Hive data source" do
      #status.should == 200
    end
  end


end
