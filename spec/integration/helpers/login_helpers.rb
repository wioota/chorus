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

    page.should have_content("Recent Activity")
    wait_until { current_route == '' || page.all('.has_error').size > 0 || page.all('.errors li').size > 0 }
  end

  def logout
    visit("/#/logout")
  end
end
