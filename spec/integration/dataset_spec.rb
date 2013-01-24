require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Dataset", :database_integration do
  let(:the_data_source) { InstanceIntegration.real_gpdb_data_source }
  let(:dataset) { the_data_source.datasets.first }
  let(:owner) { users(:admin) }
  let(:workspace) { owner.workspaces.first }

  it "associate Dataset to workspace" do
    login(owner)
    visit("#/data_sources")
    click_link the_data_source.name
    find("a", :text => /^#{dataset.schema.database.name}$/).click
    click_link dataset.schema.name
    within ".multiselect" do
      find('.select_all').click
    end

    within ".multiselect_actions" do
      find('.associate').click
    end

    within_modal do
      within ".items.collection_list" do
        find("li[data-id='#{workspace.id}']").click
      end
      click_button "Associate Datasets"
    end
    workspace.bound_datasets.should include(dataset)
  end
end