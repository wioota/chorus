require 'spec_helper'

resource 'HdfsDataset' do
  before { log_in users(:owner) }

  post "/hdfs_datasets" do
    parameter :data_source_id, "Hadoop DataSource ID"
    parameter :name, "Name"
    parameter :file_mask, "Hadoop File Mask"
    parameter :workspace_id, "Workspace ID"
    required_parameters :data_source_id, :name, :file_mask, :workspace_id

    let(:data_source_id) { HdfsDataSource.first.id }
    let(:workspace_id) { Workspace.first.id }
    let(:name) { Faker::Name.name }
    let(:file_mask) { "/*" }

    example_request "Create a Dataset from a Hadoop file mask" do
      status.should == 201
    end
  end

  put "/hdfs_datasets/:id" do
    parameter :id, "Hadoop File Mask Id"
    parameter :name, "Name"
    parameter :file_mask, "Hadoop File Mask"
    required_parameters :id

    let(:id) { datasets(:hadoop).id }
    let(:name) { Faker::Name.name }
    let(:file_mask) { "/foo/*/bar" }

    example_request "Update a Hadoop File Mask Dataset" do
      status.should == 200
    end
  end
end