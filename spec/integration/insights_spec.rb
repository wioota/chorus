require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Insights" do
   it "clicks on the insights link on the home page" do
    login(users(:owner))
    wait_for_ajax
    click_link "Insights"
    wait_for_ajax
    wait_until {page.find(".title h1").text == "Insights"}
  end

  it "creates an insight" do
    login(users(:owner))
    within ".dashboard_workspace_list.list" do
      click_link workspaces(:public).name
    end
    wait_for_ajax
    click_link "Add an insight"

    within_modal(30) do
      set_cleditor_value("body", "This is adding an Insight")
      click_on "Add Insight"
    end
  end
end
