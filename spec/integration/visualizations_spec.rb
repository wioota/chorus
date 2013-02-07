require File.join(File.dirname(__FILE__), 'spec_helper')

#These tests actually create the charts from the instances view. Need to write separate tests for visualization from sandbox

describe "Visualizations", :greenplum_integration do
  let(:instance) { InstanceIntegration.real_gpdb_data_source }
  let(:database) { InstanceIntegration.real_database }
  let(:schema) { database.schemas.find_by_name("test_schema") }
  let(:table) { schema.datasets.find_by_name("base_table1") }
  let(:configure_chart) {}
  let(:save_type) { 'desktop_image' }
  let(:workspace) { workspaces(:image) }

  before do
    login(users(:admin))
    visit("#/data_sources")
    find("a", :text => /^#{instance.name}$/).click
    find("a", :text => /^#{database.name}$/).click
    find("a", :text => /^#{schema.name}$/).click
    find("a", :text => /^#{table.name}$/).click
    find(".list li.selected").click
    click_button "Visualize"
  end

  shared_examples "a visualization" do
    it "should create a chart" do
      find(".chart_icon.#{chart_type}").click
      configure_chart
      click_button "Create Chart"

      within_modal do
        page.should have_content "Visualization: #{table.name}"
        click_link "Show Data Table"
        page.should have_content "Results Console"
        click_link "Hide Data Table"
        save_as(save_type)
        # We would like to make an assertion about the content-type header or response code,
        # but Selenium does not support this. Add assertion if we move to different driver.
        click_button "Close"
      end

      counter = 0
      while page.evaluate_script("$.active != 0")  do
        sleep 1
        counter += 1
        if counter > 60
          pa "AJAX too slow in visualization spec"
          break
        end
      end

      logout
    end
  end

  describe "Create frequency plot" do
    let(:chart_type) { 'frequency' }

    context "and save as a desktop image" do
      it_behaves_like "a visualization"
    end

    context "and save as a workfile" do
      let(:save_type) { 'workfile_image' }

      it_behaves_like "a visualization"
    end

    context "and save as a note attachment" do
      let(:save_type) { 'note_attachment' }

      it_behaves_like "a visualization"
    end
  end

  def save_as(type)
    case type
      when 'desktop_image'
      save_desktop_image
    when 'workfile_image'
      expect {
        save_workfile_image
      }.to change(Workfile, :count).by(1)
    when 'note_attachment'
      expect {
        save_note_attachment
      }.to change(Events::Note, :count).by(1)
    end
  end

  def save_desktop_image
    click_button "Save As..."
    find(:xpath, "//a[contains(., 'Desktop Image')]").click
  end

  def save_workfile_image
    click_button "Save As..."
    find(:xpath, "//a[contains(., 'Work File Image')]").click
    find("li[data-id='#{workspace.id}']").click
    click_button 'Save'
    find("button.save", :text => "Save As...")
  end

  def save_note_attachment
    click_button "Save As..."
    find(:xpath, "//a[contains(., 'Note Attachment')]").click
    set_cleditor_value("body", "Note on the visualization")
    click_button "Add Note"
    find("button.save", :text => "Save As...")
  end
end