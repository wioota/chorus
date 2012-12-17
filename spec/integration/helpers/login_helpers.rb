module LoginHelpers
  def current_route
    URI.parse(current_url).fragment
  end

  def login(userOrUsername, password = FixtureBuilder.password)
    username = userOrUsername.is_a?(String) ? userOrUsername : userOrUsername.username
    visit(WEBPATH['login_route'])
    fill_in 'username', :with => username
    fill_in 'password', :with => password
    click_button "Login"

    page.should have_no_selector(".loading_section")
    page.should have_content("Recent Activity")
  end

  def logout
    visit("/#/logout")
  end
end
