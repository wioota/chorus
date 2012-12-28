require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Import Console", :database_integration do
  before do
    login(users(:admin))
  end

  let(:dataset) { datasets(:forever_chorus_view) }
  let(:workspace) { dataset.workspace }

  def clean_up
    dataset.schema.connect_with(dataset.gpdb_instance.owner_account).drop_table("forever_table")
  end

  before do
    Import.delete_all # remove existing fixtures
    clean_up
  end
  after { clean_up }

  it "shows a list of pending imports" do
    visit "#/workspaces/#{workspace.id}/chorus_views/#{dataset.id}"
    click_on "Import Now"
    fill_in "toTable", :with => "forever_table"
    page.should have_content "Begin Import"
    click_on "Begin Import"
    sleep 2
    screenshot_and_save_page

    visit '/import_console'
    source_path = "#{dataset.schema.database.name}.#{dataset.schema.name}.#{dataset.name}"
    destination_path = "#{workspace.sandbox.database.name}.#{workspace.sandbox.name}.forever_table"
    page.should have_content destination_path

    click_on source_path
    page.should have_content dataset.name

  end
end
