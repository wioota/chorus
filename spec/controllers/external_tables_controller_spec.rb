require 'spec_helper'

describe ExternalTablesController do
  let(:user) { users(:the_collaborator) }
  let(:sandbox) { gpdb_schemas(:default) }
  let(:workspace) { workspaces(:public) }
  let(:workspace_without_sandbox) { workspaces(:private) }
  let(:hdfs_entry) { FactoryGirl.create(:hdfs_entry, :path => '/data.csv', :hadoop_instance => hadoop_instance)}

  let!(:instance_account) { sandbox.gpdb_instance.account_for_user!(user) }
  let(:hadoop_instance) { hadoop_instances(:hadoop) }

  let(:parameters) do
    {
        :column_names => ["field1", "field2"],
        :delimiter => ',',
        :file_expression => '*.txt',
        :hadoop_instance_id => hadoop_instance.id,
        :has_header => true,
        :hdfs_entry_id => hdfs_entry,
        :pathname => "foo_fighter/twisted_sisters/",
        :table_name => "highway_to_heaven",
        :types => ["text", "text"],
        :workspace_id => workspace.id
    }
  end

  describe "#create" do
    before do
      log_in user
    end

    it_behaves_like "an action that requires authentication", :post, :create, :workspace_id => '-1'

    context "without sandbox" do
      let(:workspace) { workspace_without_sandbox }

      it "fails and responds unprocessable entity" do
        post :create, parameters
        response.code.should == "422"

        decoded = JSON.parse(response.body)
        decoded['errors']['fields']['external_table'].should have_key('EMPTY_SANDBOX')
      end
    end

    context "with sandbox" do
      it "creates hdfs external table and responds with ok" do
        mock(ExternalTable).build(anything) do |e|
          e[:column_names].should == ['field1', 'field2']
          e[:column_types].should == ["text", "text"]
          e[:database].should == Gpdb::ConnectionBuilder.url(sandbox.database, instance_account)
          e[:delimiter].should == ','
          e[:file_expression].should == '*.txt'
          e[:has_header].should == true
          e[:location_url].should == hdfs_entry.url
          e[:name].should == 'highway_to_heaven'
          e[:schema_name].should == 'default'
          mock(Object.new).save { true }
        end

        # Please get rid of me
        stub(Dataset).refresh {
          d = workspace.sandbox.datasets.build
          d.name = 'highway_to_heaven'
          d.save!
        }

        expect {
          post :create, parameters
        }.to change(Events::WorkspaceAddHdfsAsExtTable, :count).by(1)
        response.code.should == "200"
      end

      it "presents any errors that come from the model" do
        mock(ExternalTable).build(anything) do |e|
          o = ExternalTable.new
          mock(o).save { o.errors.add(:name, :TAKEN); false }
        end

        post :create, parameters
        response.code.should == "422"
        decoded_response = JSON.parse(response.body)
        decoded_response['errors']['fields']['name'].should have_key('TAKEN')
      end
    end
  end
end
