require 'spec_helper'

describe ExternalTablesController do
  let(:user) { users(:the_collaborator) }
  let(:workspace) { workspaces(:public) }

  let!(:instance_account) { sandbox.gpdb_instance.account_for_user!(user) }
  let(:sandbox) { gpdb_schemas(:default) }

  let(:hadoop_instance) { hadoop_instances(:hadoop) }
  let(:hdfs_entry) { hdfs_entries(:hdfs_file) }
  let(:hdfs_directory) { hdfs_entries(:directory) }

  before { log_in user }

  describe "#create" do
    def mock_gpdb_success
      mock(ExternalTable).build(anything) do |e|
        yield e if block_given?
        mock(Object.new).save { true }
      end

      # Please get rid of me
      stub(Dataset).refresh do
        workspace.sandbox.datasets.create!(:name => 'tablefromhdfs')
      end
    end

    let(:parameters) do
      {
          :column_names => ["field1", "field2"],
          :delimiter => ',',
          :id => hadoop_instance.id,
          :has_header => true,
          :hdfs_entry_id => hdfs_entry,
          :pathname => "foo_fighter/twisted_sisters/",
          :table_name => "tablefromhdfs",
          :types => ["text", "text"],
          :workspace_id => workspace.id
      }
    end

    it_behaves_like "an action that requires authentication", :post, :create, :workspace_id => '-1'

    context "A workspace without a sandbox" do
      let(:workspace) { workspaces(:private) }

      it "fails and responds unprocessable entity" do
        post :create, parameters
        response.code.should == "422"
        JSON.parse(response.body)['errors']['fields']['external_table'].should have_key('EMPTY_SANDBOX')
      end
    end

    it "initializes and calls into ExternalTable correctly" do
      mock_gpdb_success do |ext_table_params|
        ext_table_params[:column_names].should == ['field1', 'field2']
        ext_table_params[:column_types].should == ["text", "text"]
        ext_table_params[:database].should == Gpdb::ConnectionBuilder.url(sandbox.database, instance_account)
        ext_table_params[:delimiter].should == ','
        ext_table_params[:has_header].should == true
        ext_table_params[:location_url].should == hdfs_entry.url
        ext_table_params[:name].should == 'tablefromhdfs'
        ext_table_params[:schema_name].should == 'default'
      end

      post :create, parameters
      response.should be_success
    end

    it "creates an HdfsFileExtTableCreated event with the hdfs file" do
      mock_gpdb_success

      expect {
        post :create, parameters
      }.to change(Events::HdfsFileExtTableCreated, :count).by(1)

      e = Events::Base.last
      e.workspace.should    == workspace
      e.dataset.name.should == 'tablefromhdfs'
      e.hdfs_entry.should    == hdfs_entry
    end

    it 'creates an HdfsDirectoryExtTableCreated event for the directory' do
      mock_gpdb_success

      expect {
        post :create, parameters.merge!(:hdfs_entry_id => hdfs_directory.id)
      }.to change(Events::HdfsDirectoryExtTableCreated, :count).by(1)
      e = Events::Base.last
      e.workspace.should       == workspace
      e.dataset.name.should    == 'tablefromhdfs'
      e.hdfs_entry.should       == hdfs_directory
    end

    it 'creates an HdfsPatternExtTableCreated event for the file pattern' do
      mock_gpdb_success

      expect {
        post :create, parameters.merge(:file_pattern => '*.csv', :hdfs_entry_id => hdfs_directory.id)
      }.to change(Events::HdfsPatternExtTableCreated, :count).by(1)
      e = Events::Base.last
      e.workspace.should       == workspace
      e.dataset.name.should    == 'tablefromhdfs'
      e.hdfs_entry.should       == hdfs_directory
      e.file_pattern.should == '*.csv'
    end

    it "presents any errors that come from the model" do
      mock(ExternalTable).build(anything) do
        o = ExternalTable.new
        mock(o).save { o.errors.add(:name, :TAKEN); false }
      end

      post :create, parameters
      response.code.should == "422"
      JSON.parse(response.body)['errors']['fields']['name'].should have_key('TAKEN')
    end
  end
end
