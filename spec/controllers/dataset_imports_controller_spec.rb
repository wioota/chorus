require 'spec_helper'

describe DatasetImportsController do
  describe "#index" do
    let(:user) { users(:owner) }
    let(:source_dataset) { import_three.source_dataset }

    let(:import_one) { imports(:one) }
    let(:import_two) { imports(:two) }
    let(:import_three) { imports(:three) }

    before do
      log_in user
    end

    it "uses authorization based on the visible datasets"

    it_behaves_like "a paginated list" do
      let(:params) {{:workspace_id => import_three.workspace_id, :dataset_id => source_dataset.id}}
    end

    it "shows the latest imports for a dataset as the source dataset" do
      get :index, :workspace_id => import_three.workspace_id, :dataset_id => source_dataset.id
      response.should be_success
      decoded_response.should_not be_nil
      decoded_response.length.should == 3
    end

    context "for a destination dataset" do
      let(:workspace) { import_three.workspace }
      let(:destination_dataset) { workspace.sandbox.datasets.create!({:name => 'new_table_for_import'}, :without_protection => true) }

      it "shows the latest imports for a destination dataset" do
        get :index, :workspace_id => workspace.id, :dataset_id => destination_dataset.id
        response.should be_success
        decoded_response.length.should == 3
      end
    end

    it "authorizes" do
      log_in users(:default)
      get :index, :workspace_id => workspaces(:private).id, :dataset_id => source_dataset.id

      response.should be_forbidden
    end

    generate_fixture 'datasetImportSet.json' do
      get :index, :workspace_id => import_three.workspace_id, :dataset_id => source_dataset.id
      response.should be_success
    end

    generate_fixture 'csvImportSet.json' do
      get :index, :workspace_id => imports(:csv).workspace_id, :dataset_id => datasets(:csv_import_table).id
      response.should be_success
    end
  end

  describe "#create", :database_integration => true do
    let(:account) { InstanceIntegration.real_gpdb_account }
    let(:user) { account.owner }
    let(:database) { InstanceIntegration.real_database }
    let(:schema) { database.schemas.find_by_name('test_schema') }
    let(:src_table) { database.find_dataset_in_schema('base_table1', 'test_schema') }
    let(:archived_workspace) { workspaces(:archived) }
    let(:active_workspace) { workspaces(:public) }

    let(:attributes) {
      HashWithIndifferentAccess.new(
          :to_table => "the_new_table",
          :sample_count => "12",
          :workspace_id => active_workspace.id.to_s,
          :truncate => "false"
      )
    }

    def call_sql(schema, account, sql_command)
      schema.with_gpdb_connection(account) do |connection|
        connection.exec_query(sql_command)
      end
    end

    before(:each) do
      log_in account.owner
    end

    after(:each) do
      call_sql(schema, account, "DROP TABLE IF EXISTS the_new_table")
    end

    context "when importing a dataset immediately" do
      context "into a new destination dataset" do
        before do
          attributes[:new_table] = "true"
          attributes.merge! :dataset_id => src_table.to_param, :workspace_id => active_workspace.id
        end

        let(:active_workspace) { FactoryGirl.create :workspace, :name => "TestImportWorkspace", :sandbox => schema, :owner => user }

        it "uses authorization" do
          mock(subject).authorize! :can_edit_sub_objects, active_workspace
          post :create, attributes
        end

        it "enqueues a new ImportExecutor.run job for active workspaces and returns success" do
          mock(QC.default_queue).enqueue_if_not_queued("ImportExecutor.run", anything) do |method, import_id|
            Import.find(import_id).tap do |import|
              import.workspace.should == active_workspace
              import.to_table.should == "the_new_table"
              import.source_dataset.should == src_table
              import.truncate.should == false
              import.user_id == user.id
              import.sample_count.should == 12
              import.new_table.should == true
            end
          end

          post :create, attributes
          response.should be_success
        end

        it "makes a DATASET_IMPORT_CREATED event" do
          expect {
            post :create, attributes
          }.to change(Events::DatasetImportCreated, :count).by(1)

          event = Events::DatasetImportCreated.last
          event.actor.should == user
          event.dataset.should == nil
          event.source_dataset.should == src_table
          event.workspace.should == active_workspace
          event.destination_table.should == 'the_new_table'
        end

        it "should return error for archived workspaces" do
          attributes[:workspace_id] = archived_workspace.id
          expect {
            post :create, attributes
          }.to change(Events::DatasetImportCreated, :count).by(0)
          response.code.should == "422"
        end

        it "should return successfully for active workspaces" do
          post :create, attributes
          response.code.should == "201"
          response.body.should == "{}"
        end

        it "throws an error if table already exists" do
          post :create, attributes.merge(:to_table => "master_table1")
          response.code.should == "422"

          decoded_errors.fields.base.TABLE_EXISTS.should be_present
        end

        it "throws an error if source table can't be found" do
          post :create, attributes.merge(:dataset_id => 'missing_source_table')
          response.code.should == "404"
        end

        context "when there's duplicate columns ( only in Chorus View )" do
          before do
            any_instance_of(Dataset) do |dataset|
              mock(dataset).check_duplicate_column.with_any_args { }
            end
          end
          it "should check for duplicate columns" do
            post :create, attributes
          end
        end
      end

      context "when importing into an existing table" do
        let(:dst_table_name) { active_workspace.sandbox.datasets.first.name }

        before do
          attributes[:new_table] = "false"
          attributes[:to_table] = dst_table_name
          attributes.merge! :dataset_id => src_table.to_param, :workspace_id => active_workspace.id
        end

        context "when destination dataset is consistent with source" do
          before do
            any_instance_of(Dataset) do |d|
              stub(d).dataset_consistent? { true }
            end
          end

          it "creates an import for the correct dataset and returns success" do
            expect {
              post :create, attributes
            }.to change(Import, :count).by(1)
            response.should be_success
            last_import = Import.last
            last_import.source_dataset.id.should == src_table.id
            last_import.new_table.should be_false
            last_import.to_table.should_not be_nil
            last_import.sample_count.should == 12
            last_import.truncate.should be_false
          end

          it "makes a DATASET_IMPORT_CREATED event" do
            expect {
              post :create, attributes
            }.to change(Events::DatasetImportCreated, :count).by(1)
            event = Events::DatasetImportCreated.last

            event.actor.should == user
            event.dataset.name.should == dst_table_name
            event.source_dataset.should == src_table
            event.workspace.should == active_workspace
            event.destination_table.should == dst_table_name
          end
        end

        it "throws an error if table structure is not consistent" do
          any_instance_of(Dataset) do |d|
            stub(d).dataset_consistent? { false }
          end

          post :create, attributes
          response.code.should == "422"
          decoded_errors.fields.base.TABLE_NOT_CONSISTENT.should be_present
        end
      end
    end
  end

  describe "smoke test for import schedules", :database_integration => true do
    # In the test, use gpfdist to move data between tables in the same schema and database
    let(:instance_account) { InstanceIntegration.real_gpdb_account }
    let(:user) { instance_account.owner }
    let(:database) { InstanceIntegration.real_database }
    let(:schema_name) { 'test_schema' }
    let(:schema) { database.schemas.find_by_name(schema_name) }
    let(:source_table) { "candy" }
    let(:source_table_name) { "\"#{schema_name}\".\"#{source_table}\"" }
    let(:destination_table_name) { "dst_candy" }
    let(:destination_table_fullname) { "\"test_schema\".\"dst_candy\"" }
    let(:workspace) { workspaces(:public).tap { |ws| ws.owner = user; ws.members << user; ws.sandbox = schema; ws.save! } }
    let(:sandbox) { workspace.sandbox }

    let(:gpdb_params) do
      {
          :host => instance_account.gpdb_instance.host,
          :port => instance_account.gpdb_instance.port,
          :database => database.name,
          :username => instance_account.db_username,
          :password => instance_account.db_password,
          :adapter => "jdbcpostgresql"}
    end

    let(:gpdb1) { ActiveRecord::Base.postgresql_connection(gpdb_params) }
    let(:gpdb2) { ActiveRecord::Base.postgresql_connection(gpdb_params) }

    let(:table_def) { '"id" numeric(4,0),
                   "name" character varying(255),
                    "id2" integer,
                    "id3" integer,
                    "date_test" date,
                    "fraction" double precision,
                    "numeric_with_scale" numeric(4,2),
                    "time_test" time without time zone,
                    "time_with_precision" time(3) without time zone,
                    "time_with_zone" time(3) with time zone,
                    "time_stamp_with_precision" timestamp(3) with time zone,
                    PRIMARY KEY("id2", "id3", "id")'.tr("\n", "").gsub(/\s+/, " ").strip }

    let(:source_dataset) { schema.datasets.find_by_name(source_table) }
    let(:import_attributes) do
      {
          :workspace => workspace,
          :to_table => destination_table_name,
          :new_table => true,
          :dataset => nil,
          :truncate => false,
          :destination_table => destination_table_name,
          :dataset_id => source_dataset.id,
          :workspace_id => workspace.id
      }
    end

    let(:start_time) { "2012-08-23 23:00:00.0" }

    let(:create_source_table) do
      gpdb1.exec_query("delete from #{source_table_name};")
    end

    def setup_data
      gpdb1.exec_query("insert into #{source_table_name}(id, name, id2, id3) values (1, 'marsbar', 3, 5);")
      gpdb1.exec_query("insert into #{source_table_name}(id, name, id2, id3) values (2, 'kitkat', 4, 6);")
      gpdb2.exec_query("drop table if exists #{destination_table_fullname};")
    end

    before do
      log_in user
      create_source_table

      stub(GpPipe).gpfdist_url { Socket.gethostname }
      stub(GpPipe).grace_period_seconds { 1 }
      setup_data
      # synchronously run all queued import jobs
      mock(QC.default_queue).enqueue_if_not_queued("ImportExecutor.run", anything) do |method, import_id|
        ImportExecutor.run import_id
      end
    end

    it "copies data" do
      expect {
        expect {
          post :create, import_attributes
        }.to change(Events::DatasetImportCreated, :count).by(1)
      }.to change(Events::DatasetImportSuccess, :count).by(1)
      check_destination_table
    end

    after do
      gpdb2.exec_query("drop table if exists #{destination_table_fullname};")
      gpdb1.try(:disconnect!)
      gpdb2.try(:disconnect!)
      # We call src_schema from the test, although it is only called from run outside of tests, so we need to clean up
      #gp_pipe.src_conn.try(:disconnect!)
      #gp_pipe.dst_conn.try(:disconnect!)
    end

    def check_destination_table
      gpdb2.exec_query("SELECT * FROM #{destination_table_fullname}").length.should == 2
    end
  end
end
