require 'spec_helper'

describe Events::JobFailed do
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:owner) { workspace.owner }
  let(:member) { users(:the_collaborator) }
  let(:non_member) { users(:no_collaborators) }

  let(:event) { Events::JobFailed.by(owner).add(:job => job, :workspace => workspace) }

  it "on creation, notifies all members of its workspace" do
    expect {
      expect {
        event
      }.to change(member.notifications, :count).by(1)
    }.not_to change(non_member.notifications, :count)

    member.notifications.last.event.should == event
  end
end