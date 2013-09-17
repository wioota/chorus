require 'spec_helper'
require_relative 'helpers'

describe Events::ProjectStatusChanged do
  extend EventHelpers
  let(:workspace) { FactoryGirl.create(:workspace) }
  let(:actor) { users(:default) }

  subject { Events::ProjectStatusChanged.by(actor).add(:workspace => workspace) }

  its(:targets) { should == { :workspace => workspace } }

  it_creates_activities_for { [actor, workspace] }
  it_does_not_create_a_global_activity

  it "sets the status and reason from the workspace" do
    Events::ProjectStatusChanged.by(actor).add(:workspace => workspace)

    Events::ProjectStatusChanged.last.status.should == workspace.project_status
    Events::ProjectStatusChanged.last.reason.should == workspace.project_status_reason
  end
end
