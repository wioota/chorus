require 'spec_helper'

describe Events::JobSucceeded do
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:owner) { job.owner }
  let(:member) { users(:the_collaborator) }
  let(:non_member) { users(:no_collaborators) }
  let(:job_result) { job_results(:default) }
  let(:event) { Events::JobSucceeded.by(owner).add(:job => job, :workspace => workspace, :job_result => job_result) }

  context "when success_nofity is set" do
    before do
      job.update_attribute(:success_notify, 'everybody')
    end

    it "on creation, notifies all members of its workspace" do
      expect {
        expect {
          event
        }.to change(member.notifications, :count).by(1)
      }.not_to change(non_member.notifications, :count)

      member.notifications.last.event.should == event
    end

    it "emails those it notifies" do
      event
      ActionMailer::Base.deliveries.map(&:to).flatten.should =~ workspace.members.map(&:email)
    end
  end

  context "when success_notify is not set" do
    before do
      job.success_notify.should == 'nobody'
    end

    it "on creation, notifies no one" do
      expect {
        event
      }.not_to change(Notification, :count)
    end
  end

  describe 'header' do
    it "has good copy" do
      event.header.should == "Job #{job.name} succeeded in workspace #{workspace.name}."
    end
  end
end