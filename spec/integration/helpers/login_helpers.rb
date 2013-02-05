module LoginHelpers
  def current_route
    URI.parse(current_url).fragment
  end

  def login(user, password = FixtureBuilder.password)
    visit("/#/login")
    page.should have_selector("form.login")
    fill_in 'username', :with => user.username
    fill_in 'password', :with => password
    click_button "Login"

    page.find(".header .username").should have_content(user.first_name)
  end

  def logout
    visit("/#/logout")
  end
end
