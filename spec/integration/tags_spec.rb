require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'adding a tag to a workfile' do
  let(:workfile) {workfiles(:public)}
  let(:workspace) {workfile.workspace}

  before do
    login(users(:admin))
  end

  it 'adds the tags in the workfile show page' do
    visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")

    within '.content' do
      page.should have_no_selector(".loading_section")
    end

    within '.content_header' do
      page.should have_selector("#tag_editor", :visible => true)
      fill_in 'tag_editor', :with => 'new_tag'
      find('.tag_editor').native.send_keys(:return)

      fill_in 'tag_editor', :with => 'comma_separated_tag_1,comma_separated_tag_2'
      find('.tag_editor').native.send_keys(:return)
    end

    visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")
    within '.content_header' do
      page.should have_content 'new_tag'

      page.should have_content 'comma_separated_tag_1'
      page.should have_content 'comma_separated_tag_2'
      page.should_not have_content 'comma_separated_tag_1,comma_separated_tag_2'
    end
  end

  it 'adds tags to multiple work files' do
    visit("#/workspaces/#{workspace.id}/workfiles")
    within ".content" do
      find('a', :text => workfile.file_name)
    end
    within ".multiselect" do
      click_link "All"
    end

    within ".multiselect_actions" do
      find('.edit_tags').click
    end
    fill_in 'tag_editor', :with => 'new_tag'
    find('.tag_editor').native.send_keys(:return)
    page.should have_content 'Edit Tags' #Waiting for tags to be posted to server
    click_button "Close"
    within ".main_content" do
      total_workfiles = 0
      within ".content" do
        total_workfiles = all('.workfile').count
      end
      all('a', :text => 'new_tag').count.should == total_workfiles
    end
  end
end

describe 'viewing all the entities sharing a specific tag' do
  let(:workfile) {workfiles(:public)}
  let(:workspace) {workfile.workspace}
  let(:tag) { ActsAsTaggableOn::Tag.find_by_name('crazy_tag') }

  before do
    login(users(:admin))
    workfile.tag_list = 'crazy_tag'
    workfile.save!
  end

  it "shows list of tagged objects" do
    visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")

    find('span', :text => 'crazy_tag').click
    current_route.should == "/tags/crazy_tag"

    page.should have_content("crazy_tag")

    pending "#39968421: need to implement tag show page"

    page.should have_content(workfile.file_name)
  end
end