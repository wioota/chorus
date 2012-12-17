require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Insights" do
   it "clicks on the insights link on the home page" do
    login(users(:owner))
    click_link "Insights"
    find(".title h1").should have_content("Insights")
  end

  it "creates an insight" do
    login(users(:owner))
    within ".dashboard_workspace_list.list" do
      find("a", :text => /^#{workspaces(:public).name}$/).click()
    end

    page.should have_no_selector(".loading_section")
    click_link "Add an insight"

    within_modal do
      set_cleditor_value("body", "This is adding an Insight")
      click_button "Add Insight"
    end
  end
end
