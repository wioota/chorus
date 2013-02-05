require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Logout" do
  it "logs the user out" do
    login(users(:admin))
    find(".header .username a").click
    find(".menu.popup_username").should have_no_selector(".hidden")
    within '.menu.popup_username' do
      click_link "Sign Out"
    end
    page.should have_content("Login")
    current_route.should == "login"
  end
end
