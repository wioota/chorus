require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Chorus Views", :database_integration do
  describe "Create" do

    let(:workspace) { workspaces(:gpdb_workspace) }
    let(:dataset) { workspace.sandbox.datasets.first }

    it "creates a new chorus view" do
      login(users(:admin))
      wait_for_ajax
      visit("#/workspaces/#{workspace.id}/datasets/#{dataset.id}")
      wait_for_ajax
      click_button "Derive a Chorus View"
      click_button "Verify Chorus View"
      within_modal do
        click_button "Create Chorus View"
        fill_in 'objectName', :with => "New_Chorus_View"
        click_button "Create Chorus View"
        wait_for_ajax(30)
      end
      workspace.chorus_views.find_by_name("New_Chorus_View").should_not be_nil
    end
  end
end
