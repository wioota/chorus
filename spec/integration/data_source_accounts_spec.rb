require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Data Source Permissions" do
  let(:the_data_source) { data_sources(:chorus_gpdb40)}
  let(:no_access_user) { users(:default) }
  let(:owner) { users(:admin)}

  it "Adds new data source account" do
    login(owner)
    visit("#/instances/")
    find("li.instance[data-instance-id='#{the_data_source.id}']").click
    within '.account_info' do
      click_link "Edit"
    end

    click_button "Add Account"
    select_item('#select_new_instance_account_owner', no_access_user.id)
    within "li.editing" do
      fill_in "dbUsername", :with => "gpadmin"
      fill_in "dbPassword", :with => "secret"
      click_link "Save Changes"
    end
    click_button "Close Window"
    logout

    login(no_access_user)
    visit("#/instances/")
    click_link the_data_source.name
    page.should have_selector(".breadcrumb:contains('#{the_data_source.name}')")
  end

  it "Updates a Data Source to have a shared account" do
    login(owner)
    visit("#/instances/")
    find("li.instance[data-instance-id='#{the_data_source.id}']").click
    within '.account_info' do
      click_link "Edit"
    end

    click_link "Switch to single shared account"
    click_button "Enable shared account"
    click_button "Close Window"
    logout

    login(no_access_user)
    visit("#/instances/")
    click_link the_data_source.name
    page.should have_selector(".breadcrumb:contains('#{the_data_source.name}')")
  end
end