require 'spec_helper'

describe SandboxesController do
  ignore_authorization!

  let(:owner) { gpdb_instance.owner }
  let(:sandbox) { gpdb_schemas(:default) }
  let(:database) { sandbox.database }
  let(:gpdb_instance) { database.gpdb_instance }
  let(:workspace) { workspaces(:no_sandbox) }
  before do
    log_in owner
  end

  describe '#create' do
    it 'uses authentication' do
      mock(subject).authorize!(:update, workspace)
      post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
    end

    context 'when sandbox is an existing schema' do
      it 'sets the sandbox on the workspace' do
        expect_to_add_event(Events::WorkspaceAddSandbox, owner) do
          post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
        end

        response.code.should == '201'
        workspace.reload.sandbox_id.should == sandbox.id
        workspace.has_added_sandbox.should == true
      end
    end

    context 'with a schema that does not exist' do
      it 'returns an error' do
        post :create, :workspace_id => workspace.id, :schema_id => -1

        response.code.should == '422'
        decoded_errors.fields.database.GENERIC.message.should match /Couldn't find/
      end
    end

    context 'when new sandbox is a new schema in an existing database' do
      before do
        stub(GpdbSchema).refresh(anything, anything) {}
      end

      it 'calls create_schema' do
        any_instance_of(GpdbDatabase) do |db|
          stub(db).create_schema("create_new_schema", database.gpdb_instance.owner) do |name|
            database.schemas.create!({:name => name}, :without_protection => true)
          end
        end

        post :create, :workspace_id => workspace.id, :schema_name => "create_new_schema", :database_id => database.id
        response.code.should == '201'
        workspace.reload.sandbox.name.should == "create_new_schema"
      end

      it 'returns an error if creation fails' do
        any_instance_of(GpdbDatabase) do |db|
          stub(db).create_schema.with_any_args {
            raise Exception.new("Schema creation failed")
          }
        end
        post :create, :workspace_id => workspace.id, :schema_name => "create_new_schema", :database_id => database.id
        response.code.should == "422"
        decoded_errors.fields.schema.GENERIC.message.should == "Schema creation failed"
      end
    end

    context 'when new sandbox is a new schema in a new database' do
      before do
        stub(GpdbSchema).refresh(anything, anything) {}
      end

      it 'calls both create_database and create_schema' do
        any_instance_of(GpdbInstance) do |instance_double|
          mock(instance_double).create_database("new_database", gpdb_instance.owner) do |name|
            gpdb_instance.databases.create!({:name => name}, :without_protection => true)
          end
        end

        any_instance_of(GpdbDatabase) do |database_double|
          mock(database_double).create_schema("create_new_schema", gpdb_instance.owner) do |name|
            database = gpdb_instance.reload.databases.find_by_name("new_database")
            FactoryGirl.create :gpdb_schema, :name => name, :database => database
          end
        end

        post :create, :workspace_id => workspace.id, :schema_name => 'create_new_schema', :database_name => 'new_database', :instance_id => gpdb_instance.to_param
        response.code.should == '201'

        workspace.reload.sandbox.name.should == 'create_new_schema'
        workspace.reload.sandbox.database.name.should == 'new_database'
      end

      it 'does not call create_schema if the schema is public' do
        any_instance_of(GpdbInstance) do |instance_double|
          stub(instance_double).create_database('new_database', gpdb_instance.owner) do |name|
            database = FactoryGirl.create :gpdb_database, :name => name, :gpdb_instance => gpdb_instance
            schema = FactoryGirl.create :gpdb_schema, :name => 'public', :database => database
            database
          end
        end
        any_instance_of(GpdbDatabase) do |database_double|
          mock(database_double).create_schema.with_any_args.times(0)
        end

        post :create, :workspace_id => workspace.id, :schema_name => 'public', :database_name => 'new_database', :instance_id => gpdb_instance.to_param
        response.should be_success
        workspace.reload.sandbox.name.should == 'public'
        workspace.reload.sandbox.database.name.should == 'new_database'
      end

      it 'returns an error if creation fails' do
        any_instance_of(GpdbInstance) do |gpdb_instance|
          stub(gpdb_instance).create_database.with_any_args {
            raise Exception.new("Database creation failed")
          }
        end

        post :create, :workspace_id => workspace.id, :schema_name => 'create_new_schema', :database_name => 'new_database', :instance_id => gpdb_instance.to_param

        response.code.should == '422'
        decoded_errors.fields.database.GENERIC.message.should == 'Database creation failed'
      end
    end
  end
end

def expect_to_add_event(event_class, owner)
  expect {
    expect {
      yield
    }.to change(Events::Base, :count).by(1) # generates a single event
  }.to change(event_class.by(owner), :count).by(1)
end