require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Import Console", :database_integration do
  before do
    login(users(:admin))
  end

  let(:dataset) { datasets(:forever_chorus_view) }
  let(:workspace) { dataset.workspace }

  xit "shows a list of pending imports" do

    visit "#/workspaces/#{workspace.id}/chorus_views/#{dataset.id}"
    click_on "Import Now"
    fill_in "toTable", :with => "forever_table"
    click_on "Begin Import"

    #within ".header" do
    #  click_on users(:admin).name
    #  click_on "Sign Out"
    #end

    #login(users(:admin))
    Thread.new {
      run_jobs_synchronously
    }.run

    sleep 2
    visit '/import_console'
    page.should have_content "forever_table"
  end
end
