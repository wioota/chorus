require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Workspace datasets" do
  let(:workspace) { workspaces(:gpdb_workspace) }

  before do
    login(user)
  end

  context "when user does not have credentials for the sandbox schema" do
    let(:user) { users(:restricted_user) }

    before { visit("#/workspaces/#{workspace.id}/datasets") }

    it "prompts the user to enter credentials" do
      workspace.sandbox.data_source.account_for_user(user).should be_nil
      page.should have_text("To access data in this workspace's sandbox, enter your credentials")
    end
  end

  context "when the user has valid credentials for the sandbox schema" do
    let(:user) { users(:the_collaborator) }
    before { visit("#/workspaces/#{workspace.id}/datasets") }
    it "shows the sandbox datasets on the page" do
      page.should have_selector(".dataset_item")

      workspace.sandbox.datasets[0..5].each do |dataset|
        page.should have_text(dataset.name)
      end
    end
  end

  context "when the user has invalid credentials for the sandbox schema" do
    let(:user) { users(:the_collaborator) }

    before do
      data_source_account = workspace.sandbox.data_source.account_for_user(user)
      data_source_account.invalid_credentials!

      visit("#/workspaces/#{workspace.id}/datasets")
    end

    it "should not display an error message" do
      page.should_not have_text("You do not have privileges to access this file or directory")
    end

    it "does not show sandbox datasets" do
      workspace.sandbox.datasets[0..5].each do |dataset|
        page.should_not have_text(dataset.name)
      end
    end
  end

  context "when the user does not have credentials for an associated dataset" do
    let(:user) { users(:restricted_user) }

    before { visit("#/workspaces/#{workspace.id}/datasets") }

    it "shows the associated datasets and shows the 'add credentials' link in the sidebar" do
      page.should have_selector('.dataset_item.no_credentials')
      workspace.associated_datasets.each do |associated_dataset|
        dataset = associated_dataset.dataset
        page.find('span', :text => dataset.name).should_not be_nil
      end
    end

    it "shows the 'add credentials' link in the sidebar" do
      page.find('.notice.no_credentials').should have_text("You do not have permission to access the data source #{workspace.associated_datasets.first.dataset.data_source.name}. Click here to add your credentials.")

    end
  end
end