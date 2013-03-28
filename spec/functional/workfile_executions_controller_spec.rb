require 'spec_helper'

describe WorkfileExecutionsController, :greenplum_integration => true, :type => :controller do
  before { log_in users(:owner) }

  describe "#create" do
    context "when the query has multiple result sets" do
      let(:workspace) { workspaces(:real) }
      let(:workfile) { FactoryGirl.create(:chorus_workfile, :workspace => workspace, :execution_schema => workspace.sandbox ) }
      let(:sql) do
        <<-SQL
          select 1;
          select 2;
        SQL
      end

      it "returns the results of the last query" do
        post :create, :workfile_id => workfile.id,
             :sql => sql, :check_id => 'doesnt_even_matter',
             :download => true, :file_name => "some"

        response.should be_success
        response.body.should match(/\?column\?\n2/)
      end
    end
  end
end