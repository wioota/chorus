require "spec_helper"

describe WorkfileCopyController do
  let(:user) { users(:the_collaborator) }
  let(:workspace) { workspaces(:public) }
  let(:workfile) { workfiles(:public) }
  let(:workfile_version) { workfile.versions.first }
  let(:target_workspace) { workspaces(:public_with_no_collaborators) }

  describe "create" do
    before do
      log_in user
    end

    context "copy to a new workspace" do
      before do
        workfile_version.contents = test_file('workfile.sql')
        workfile_version.save!
      end
      it "should copy a workfile to a new active workspace" do
        lambda {
          post :create, :workfile_id => workfile.id, :workspace_id => target_workspace.id
        }.should change(target_workspace.workfiles, :count).by(1)
      end

      it "should copy latest version to a new active workspace" do
        workfile_version1 = workfile_versions(:public)
        workfile_version1.version_num =2
        workfile_version1.contents = test_file('some.txt')
        workfile_version1.save!
        post :create, :workfile_id => workfile.id, :workspace_id => target_workspace.id
        copied_workfile = Workfile.last
        File.read(workfile_version1.contents.path).should == File.read(copied_workfile.latest_workfile_version.contents.path)
      end

      it "succeeds for a public source workspace" do
        another_user = users(:no_collaborators)
        log_in another_user
        lambda {
          post :create, :workfile_id => workfile.id, :workspace_id => target_workspace.id
        }.should change(target_workspace.workfiles, :count).by(1)
        response.status.should == 201
      end

      it "fails for a private source workspace" do
        workfile = workfiles(:private)
        another_user = users(:no_collaborators)
        log_in another_user
        post :create, :workfile_id => workfile.id, :workspace_id => target_workspace.id
        response.status.should == 403
      end

      it "should not copy if user is not a member of target workspace" do
        another_user = users(:owner)
        log_in another_user
        post :create, :workfile_id => workfile.id, :workspace_id => target_workspace.id
        response.status.should == 403
      end

      it "should resolve workfile name conflicts" do
        FactoryGirl.create(:workfile, :file_name => workfile.file_name, :workspace => target_workspace)
        post :create, :workfile_id => workfile.id, :workspace_id => target_workspace.id
        response.status.should == 201
        copied_workfile = Workfile.last
        copied_workfile.file_name.should == workfile.file_name + "_1"
      end
    end

    context "copy within the same workspace" do
      it "creates a new workfile in that workspace" do
        workfile_version.contents = test_file('workfile.sql')
        workfile_version.save!
        post :create, :workfile_id => workfile.id, :file_name => "copied_workfile.sql"
        workfile.workspace.workfiles.find_by_file_name("copied_workfile.sql").should_not be_nil
      end

      context "if the workfile does not have versions" do
        let(:workfile) { workfiles("alpine.afm") }

        it "works" do
          post :create, :workfile_id => workfile.id, :file_name => "copied_workfile.sql"
          response.status.should == 201
        end
      end

      it "does not resolve name conflicts" do
        post :create, :workfile_id => workfile.id, :file_name => workfile.file_name
        response.status.should == 422
      end
    end
  end
end