require 'spec_helper'
require_relative 'helpers'

describe Events::WorkspaceImportCreated do
  extend EventHelpers
  let(:source_dataset) { datasets(:other_table) }
  let(:workspace) { workspaces(:public) }
  let(:actor) { users(:default) }
  let(:dataset) { datasets(:table) }
  let!(:workspace_association) { workspace.bound_datasets << source_dataset }
  subject do
    Events::WorkspaceImportCreated.add(
      :actor => actor,
      :dataset => dataset,
      :source_dataset => source_dataset,
      :workspace => workspace,
      :destination_table => dataset.name
    )
  end

  its(:dataset) { should == dataset }
  its(:targets) { should == {:workspace => workspace, :dataset => dataset, :source_dataset => source_dataset} }
  its(:additional_data) { should == {'destination_table' => dataset.name} }

  it_creates_activities_for { [actor, workspace, dataset, source_dataset] }
  it_does_not_create_a_global_activity
end