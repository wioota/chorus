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
    end

    visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")
    within '.content_header' do
      page.should have_content 'new_tag'
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