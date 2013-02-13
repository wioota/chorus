require 'spec_helper'

describe DatasetDownloadsController do
  let(:user) { users(:the_collaborator) }
  let(:instance_account) { table.data_source.account_for_user!(user) }
  let(:table) { datasets(:table) }

  before do
    log_in user
  end

  describe "#show" do
    context "with valid file content" do
      it "should response with success" do
        get :show, :dataset_id => table.to_param, :format => 'csv'

        response.code.should == "200"
      end

      it "streams the data into the template" do
        any_instance_of(DatasetStreamer) do |streamer|
          mock(streamer).enum(true) { "i am the enum" }
        end
        get :show, :dataset_id => table.to_param, :format => 'csv'
        response.body.should == 'i am the enum'
        assigns(:streamer).user.should == user
        assigns(:streamer).dataset.should == table
      end

      it "passes the row_limit to the streamer" do
        get :show, :dataset_id => table.to_param, :format => 'csv', :row_limit => '42'
        assigns(:streamer).row_limit.should == '42'
      end

      it "should set the content-type header" do
        get :show, :dataset_id => table.to_param, :format => 'csv'
        response.headers["Content-Disposition"].should == "attachment; filename=#{table.name}.csv"
      end

      it "sets stream to true which sets the correct headers" do
        get :show, :dataset_id => table.to_param, :format => 'csv'
        response.headers["Cache-Control"].should == 'no-cache'
        response.headers["Transfer-Encoding"].should == 'chunked'
      end

      it "should get a headerless enumerator when told" do
        streamer = Object.new
        stub(DatasetStreamer).new.with_any_args { streamer }
        mock(streamer).enum(false) { "foo" }
        get :show, :dataset_id => table.to_param, :format => 'csv', :header => 'false'
        response.body.should == "foo"
      end
    end

    context "for a user without an account" do
      let(:user) {users(:no_collaborators)}

      it "sets the response body to an error message, but still delivers a csv" do
        get :show, :dataset_id => table.to_param, :format => 'csv'
        response.body.should == "ActiveRecord::RecordNotFound"
        response.headers["Content-Disposition"].should == "attachment; filename=#{table.name}.csv"
        response.code.should == "200"
      end
    end
  end
end