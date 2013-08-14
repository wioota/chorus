require 'spec_helper'

describe JobAccess do
  let(:member) { users(:the_collaborator) }
  let(:non_member) { users(:no_collaborators) }
  let(:user) { non_member }
  let(:job_access) {
    controller = JobsController.new
    stub(controller).current_user { user }
    JobAccess.new(controller)
  }

  describe "#show?" do
    let(:job) do
      jobs(:default).tap {|job| job.workspace = workspace }
    end

    context "in a public workspace" do
      let(:workspace) { workspaces(:public) }

      it "always allows access" do
        job_access.can?(:show, job).should be_true
      end
    end

    context "in a private workspace" do
      let(:workspace) { workspaces(:private) }

      it "forbids access when the user is not a member nor admin" do
        job_access.can?(:show, job).should be_false
      end

      context "for a member" do
        let(:user) { member }

        it "allows access" do
          job_access.can?(:show, job).should be_true
        end
      end
    end
  end
end