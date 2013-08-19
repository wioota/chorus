require 'spec_helper'

describe Events::JobFailed do
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:owner) { job.owner }
  let(:member) { users(:the_collaborator) }
  let(:non_member) { users(:no_collaborators) }
  let(:event) { Events::JobFailed.by(owner).add(:job => job, :workspace => workspace) }

  describe "jobs where notifies is set" do
    before do
      job.update_attribute(:notifies, true)
    end

    it "on creation, notifies all members of its workspace" do
      expect {
        expect {
          event
        }.to change(member.notifications, :count).by(1)
      }.not_to change(non_member.notifications, :count)

      member.notifications.last.event.should == event
    end
  end

  describe "jobs where notifies is not set" do
    before do
      job.notifies.should be_false
    end

    it "on creation, notifies no one" do
      expect {
        event
      }.not_to change(Notification, :count)
    end
  end
end