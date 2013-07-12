require "spec_helper"

describe HdfsDatasetsController do
  let(:user) { users(:owner) }

  before do
    log_in user
    any_instance_of(HdfsDataset) do |ds|
      stub(ds).contents { ["content"] }
    end
  end

  describe '#create' do
    let(:workspace) { workspaces(:public) }
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    let(:params) do
      {:hdfs_dataset => {
          :file_mask => 'foo/*/bar',
          :data_source_id => hdfs_data_source.id,
          :workspace_id => workspace.id,
          :name => Faker::Name.name
      }}
    end

    it 'creates a Hadoop dataset from a file mask & data source' do
      expect {
        post :create, params
      }.to change { HdfsDataset.count }.by(1)
    end

    it 'renders the created dataset as JSON' do
      post :create, params
      response.code.should == "201"
      decoded_response.should_not be_empty
    end

    it 'associates the dataset with the given workspace' do
      expect {
        post :create, params
      }.to change { workspace.associated_datasets.count }.by(1)
    end
  end

  describe '#update' do
    let(:dataset) { datasets(:hadoop) }
    let!(:old_name) { dataset.name }
    let(:new_name) { 'Cephalopodiatry' }

    it "updates the attributes of the appropriate hdfs Dataset" do
      expect {
        put :update, :name => new_name, :id => dataset.id
      }.to change { dataset.reload.name }.from(old_name).to(new_name)
    end
  end
end