require 'spec_helper'

describe SandboxesController do
  ignore_authorization!

  let(:owner) { users(:no_collaborators) }
  let(:other_user) { users(:the_collaborator) }
  let(:sandbox) { sandbox = gpdb_schemas(:default) }
  let(:database) { sandbox.database }
  let(:workspace) { workspaces(:no_sandbox) }
  before do
    log_in owner
  end

  describe '#create' do
    context 'when sandbox is an existing schema' do
      it 'sets the sandbox on the workspace' do
        post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
        response.code.should == '201'

        workspace.sandbox_id.should == sandbox.id
        workspace.has_added_sandbox.should == true
      end
    end

    context 'when new sandbox is a new schema in an existing database' do
      let(:database) { gpdb_databases(:default) }

      before do
        stub(GpdbSchema).refresh(anything, anything) { }
        log_in database.gpdb_instance.owner
      end

      it "calls create_schema" do
        any_instance_of(GpdbDatabase) do |db|
          stub(db).create_schema("create_new_schema", database.gpdb_instance.owner) do |name|
            database.schemas.create!({:name => name }, :without_protection => true)
          end
        end

        send_request

        workspace.reload.sandbox.tap do |sandbox|
          sandbox.name.should == "create_new_schema"
        end
      end

      it "returns an error if creation fails" do
        any_instance_of(GpdbDatabase) do |db|
          stub(db).create_schema.with_any_args {
            raise Exception.new("Schema creation failed")
          }
        end
        send_request
        response.code.should == "422"
        decoded_errors.fields.schema.GENERIC.message.should == "Schema creation failed"
      end

      def send_request
        put :update, :id => workspace.id, :workspace => {
            :owner => {id: owner.id.to_s},
            :public => "false",
            :schema_name => "create_new_schema",
            :database_id => database.id
        }
      end
    end

  end

end
