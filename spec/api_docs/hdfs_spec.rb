require 'spec_helper'

resource "Hdfs" do
  let(:owner) { data_source.owner }
  let!(:data_source) { hdfs_data_sources(:hadoop) }
  let!(:dir_entry) { HdfsEntry.create!({:path => '/files', :modified_at => Time.current.to_s, :is_directory => "true", :content_count => "3", :hdfs_data_source => data_source}, :without_protection => true) }
  let!(:file_entry) { HdfsEntry.create!({:path => '/test.txt', :modified_at => Time.current.to_s, :size => "1234kB", :hdfs_data_source => data_source}, :without_protection => true ) }
  let(:hdfs_data_source_id) { data_source.to_param }

  before do
    log_in owner
    stub(Hdfs::QueryService).version_of(anything) { "1.0.0" }

    service = Object.new
    stub(Hdfs::QueryService).new(data_source.host, data_source.port, data_source.username, data_source.version) { service }
    stub(service).show('/test.txt') { ["This is such a nice file.", "It's my favourite file.", "I could read this file all day.'"] }
    stub(HdfsEntry).list('/', data_source) { [dir_entry, file_entry] }
    stub(HdfsEntry).list('/files/', data_source) { [file_entry] }
    stub(HdfsEntry).list('/test.txt', data_source) { [file_entry] }
  end

  post "/hdfs_data_sources" do
    parameter :name, "Name to show Chorus users for data source"
    parameter :description, "Description of data source"
    parameter :host, "Host IP or address of Hadoop data source"
    parameter :port, "Port of Hadoop data source"
    parameter :username, "Username for connection to data source"
    parameter :group_list, "Group list for connection"

    let(:name) { "Sesame_Street" }
    let(:description) { "Can you tell me how to get..." }
    let(:host) { "sesame.street.local" }
    let(:port) { "8020" }
    let(:username) { "big" }
    let(:group_list) { "bird" }

    required_parameters :name, :host, :port, :username, :group_list

    example_request "Register a Hadoop data source" do
      status.should == 201
    end
  end

  put "/hdfs_data_sources/:id" do
    parameter :id, "Hadoop data source id"
    parameter :name, "Name to show Chorus users for data source"
    parameter :description, "Description of data source"
    parameter :host, "Host IP or address of Hadoop data source"
    parameter :port, "Port of Hadoop data source"
    parameter :username, "Username for connection to data source"
    parameter :group_list, "Group list for connection"

    let(:name) { "a22_Duck_Street" }
    let(:description) { "Quack!" }
    let(:host) { "duck.heroku.com" }
    let(:port) { "8121" }
    let(:username) { "donaldd" }
    let(:group_list) { "scroogemcduck" }
    let(:id) { data_source.id }

    required_parameters :name, :host, :port, :username, :group_list

    example_request "Update the details on a hadoop data source" do
      status.should == 200
    end
  end

  get "/hdfs_data_sources" do
    pagination

    example_request "Get a list of registered Hadoop data sources" do
      status.should == 200
    end
  end

  get "/hdfs_data_sources/:id" do
    parameter :id, "Hadoop data source id"

    let(:id) { data_source.to_param }

    example_request "Get data source details"  do
      status.should == 200
    end
  end

  get "/hdfs_data_sources/:hdfs_data_source_id/files" do
    parameter :hdfs_data_source_id, "Hadoop data source id"

    example_request "Get a list of files for a specific hadoop data source's root directory"  do
      status.should == 200
    end
  end

  get "/hdfs_data_sources/:hdfs_data_source_id/files/:id" do
    parameter :hdfs_data_source_id, "Hadoop data source id"
    parameter :id, "HDFS file id"

    let(:id) { dir_entry.id }

    example_request "Get a list of files for a subdirectory of a specific hadoop data source"  do
      status.should == 200
    end
  end
end

 
