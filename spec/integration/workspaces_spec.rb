require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Workspaces" do
  before do
    login(users(:admin))
  end

  describe "Create workspaces" do
    it "creates a private workspace" do
      visit('#/workspaces')
      click_button "Create Workspace"
      within_modal do
        fill_in 'name', :with => "New Workspace"
        uncheck "Make this workspace publicly available"
        click_button "Create Workspace"
      end
      click_link "Dismiss the workspace quick start guide"
      logout
      login(users(:no_collaborators))
      visit('#/workspaces')
      page.should_not have_content ("Private Workspace")
    end

    it "creates a public workspace" do
      visit('#/workspaces')
      click_button "Create Workspace"
      within_modal do
        fill_in 'name', :with => "New Workspace"
        click_button "Create Workspace"
      end
      click_link "Dismiss the workspace quick start guide"
      page.should have_content('All Activity')
      Workspace.find_by_name("New Workspace").should_not be_nil
    end
  end

  describe "Delete a workspace" do
    let(:workspace) { workspaces(:public) }

    it "deletes the workspace" do
      visit("#/workspaces/#{workspace.id}")
      click_link "Delete this Workspace"
      page.should have_selector(".submit")
      find(".submit").click

      visit('/#/workspaces')
      within '.content' do
        page.should have_no_selector(".loading")
      end

      find('a', :text => "Active Workspaces", :visible => true).click
      find('a', :text => "All Workspaces", :visible => true).click
      within ".workspace_list" do
        page.should_not have_link(workspace_url(workspace))
      end
    end
  end
end