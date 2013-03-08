require 'spec_helper'

describe HdfsDataSourcesController do
  ignore_authorization!

  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }

  before do
    @user = users(:no_collaborators)
    log_in @user
  end

  describe "#create" do
    context "with valid attributes" do
      before do
        stub(Hdfs::DataSourceRegistrar).create!( {}, @user) { hdfs_data_source }
      end

      it "reports that the instance was created" do
        post :create
        response.code.should == "201"
      end

      it "renders the newly created instance" do
        post :create
        decoded_response.name.should == hdfs_data_source.name
      end

      it "schedules a job to refresh the instance" do
        mock(QC.default_queue).enqueue_if_not_queued("HdfsDataSource.refresh", numeric)
        post :create
      end
    end
  end

  describe "#update" do
    let(:attributes) { {'name' => 'some_random_value'} }
    let(:params) { attributes.merge :id => hdfs_data_source }
    let(:fake_instance) { Object.new }

    it "presents the updated hadoop data source" do
      mock(Hdfs::DataSourceRegistrar).update!(hdfs_data_source.id, attributes, @user) { fake_instance }
      it_uses_authorization(:edit, hdfs_data_source)
      mock_present { |instance| instance.should == fake_instance }
      put :update, params
    end

    context "when it fails due to validation" do
      let(:attributes) { {'name' => 'some_wrong_value'} }

      before do
        mock(Hdfs::DataSourceRegistrar).update!(hdfs_data_source.id, attributes, @user) do
          raise(ActiveRecord::RecordInvalid.new(hdfs_data_source))
        end
      end

      it "responds with validation error" do
        put :update, params
        response.code.should == "422"
      end
    end
  end

  describe "#index" do
    it "presents all hadoop data sources" do
      mock_present { |models| models.to_a.to_a.should =~ HdfsDataSource.all.to_a }
      get :index
    end

    it_behaves_like "a paginated list"
  end

  describe "#show" do
    it "presents the hadoop data source with the given id" do
      get :show, :id => hdfs_data_source.id
      decoded_response.name.should == hdfs_data_source.name
    end

    generate_fixture "hdfsDataSource.json" do
      get :show, :id => hdfs_data_source.id
    end
  end
end
