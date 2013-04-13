require 'spec_helper'

describe Workspaces::CsvImportsController do
  let(:user) { users(:owner) }
  let(:to_table) { "some_new_table" }
  let(:csv_file) { FactoryGirl.create(:csv_file, :workspace => workspace, :user => user) }
  let(:workspace) { workspaces(:public) }
  let(:column_names) { %w(a b c) }
  let(:types) { %w(integer integer integer) }
  let(:delimiter) { ',' }
  let(:has_header) { true }

  let(:file_params) do
    {
        column_names: column_names,
        types: types,
        delimiter: delimiter,
        has_header: has_header.to_s
    }
  end

  let(:params) do
    {
        workspace_id: workspace.to_param,
        csv_id: csv_file.to_param,
        csv_import: csv_import
    }
  end

  let(:csv_import) do
    file_params.merge(import_params)
  end

  let(:import_params) { {} }

  before do
    log_in user
  end

  it "uses authentication" do
    mock(subject).authorize! :create, csv_file
    post :create, params
  end

  context "when the import is created successfully" do
    before do
      mock(CsvImport).create!.with_any_args { true }
    end

    it "presents an empty array" do
      mock_present { |model| model.should == [] }
      post :create, params
    end
  end
end
