require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Dataset", :database_integration do
  let(:data_source) { GreenplumIntegration.real_data_source }
  let(:dataset) { data_source.datasets.views_tables.first }
  let(:owner) { users(:admin) }
  let(:workspace) { owner.workspaces.first }

  it "associate Dataset to workspace" do
    login(owner)
    visit("#/data_sources")
    click_link data_source.name
    find("a", :text => /^#{dataset.schema.database.name}$/).click
    find("a", :text => /^#{dataset.schema.name}$/).click

    wait_for_page_load

    click_link 'All'
    click_link 'Associate with a workspace'

    within_modal do
      within ".items.collection_list" do
        find("li[data-id='#{workspace.id}']").click
      end
      click_button "Associate Datasets"
    end
    workspace.source_datasets.should include(dataset)
  end
end