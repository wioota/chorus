require "spec_helper"

describe HdfsDataset do
  let(:dataset) { datasets(:hadoop) }

  describe 'validations' do
    it { should validate_presence_of :file_mask }
    it { should belong_to(:hdfs_data_source) }
  end

  describe 'execution_location' do
    it "returns the Dataset's Hadoop DataSource" do
      dataset.execution_location.should == dataset.hdfs_data_source
    end
  end

  describe 'associable?' do
    it 'is true' do
      dataset.should be_associable
    end
  end

  describe "workspace association" do
    let(:workspace) { workspaces(:public) }
    before do
      dataset.bound_workspaces = []
      workspace.associate_datasets(users(:owner), [dataset])
    end

    it "can be bound to workspaces" do
      dataset.reload.bound_workspaces.should include workspace
    end
  end

  describe '.assemble!' do
    let(:file_mask) {'foo/bat/bar'}
    let(:attributes) do
      {
          :file_mask => file_mask,
          :name => Faker::Name.name
      }
    end
    let(:data_source) { hdfs_data_sources(:hadoop) }
    let(:workspace)   { workspaces(:public) }
    let(:user)        { users(:owner) }
    let(:dataset)     { HdfsDataset.assemble!(attributes, data_source, workspace, user) }

    it "creates a dataset associated with the given datasource & workspace" do
      # Method under test hidden in test setup, in 'let' block :dataset.

      dataset.data_source.should == data_source
      dataset.bound_workspaces.should include(workspace)
      dataset.file_mask.should == file_mask
    end
  end

  describe 'contents' do
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    before do
      any_instance_of(Hdfs::QueryService) do |h|
        stub(h).show(dataset.file_mask) { ["content"] }
      end
    end

    it "returns the contents of the hdfs dataset" do
      dataset.contents.should == ['content']
    end

    context "corrupted file in file mask" do
      before do
        any_instance_of(Hdfs::QueryService) do |h|
          stub(h).show(dataset.file_mask) { raise FileNotFoundError, "File not found on HDFS" }
        end
      end

      it "raises HdfsContentsError when not able to read the file" do
        expect {
          dataset.contents
        }.to raise_error(HdfsDataset::HdfsContentsError)
      end
    end
  end
end