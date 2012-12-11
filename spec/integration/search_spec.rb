require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Search" do
  before :all do
    stub(GpdbColumn).columns_for.with_any_args {
      []
    }
    Sunspot.searchable.each do |model|
      model.solr_index(:batch_commit => false)
    end
    Sunspot.commit
  end

  before do
    login(users(:owner))
    fill_in 'search_text', :with => 'searchquery'
    find('.chorus_search_container>input').native.send_keys(:return)
    wait_for_ajax
  end

  describe "global search" do
    it "searches all types of objects" do
      page.find(".dataset_list").should have_content(datasets(:searchquery_table).name)
      found_user = users(:owner)
      page.find(".user_list").should have_content("#{found_user.first_name} #{found_user.last_name}")
      page.find(".hdfs_list").should have_content(hdfs_entries(:searchable).name)
      page.find(".workspace_list").should have_content(workspaces(:search_public).name)
      page.find(".workfile_list").should have_content(workfiles(:public).file_name)
      page.find(".instance_list").should have_content(gpdb_instances(:default).name)
    end
  end

  shared_examples "model specific search" do
    it "searches for only one model" do
      click_link 'All Results'
      click_link model_link
      wait_for_ajax
      current_route.should == "search/all/#{model_type}/searchquery"
      page.find(".#{model_type}_list").should have_content(found_model_text)
    end
  end

  describe "workspace search" do
    let(:model_type) { "workspace" }
    let(:found_model_text) { workspaces(:public_with_no_collaborators).name }
    let(:model_link) { "Workspaces" }
    it_behaves_like "model specific search"
  end

  describe "workfile search" do
    let(:model_type) { "workfile" }
    let(:found_model_text) { workfiles(:public).file_name }
    let(:model_link) { "Work Files" }
    it_behaves_like "model specific search"
  end

  describe "user search" do
    let(:model_type) { "user" }
    let(:found_user) { users(:owner)}
    let(:found_model_text) { "#{found_user.first_name} #{found_user.last_name}" }
    let(:model_link) { "People" }
    it_behaves_like "model specific search"
  end

  describe "instance search" do
    let(:model_type) { "instance" }
    let(:found_model_text) { gpdb_instances(:default).name }
    let(:model_link) { "Data Sources" }
    it_behaves_like "model specific search"
  end

  describe "dataset search" do
    let(:model_type) { "dataset" }
    let(:found_model_text) { datasets(:searchquery_table).name }
    let(:model_link) { "Datasets" }
    it_behaves_like "model specific search"
  end

  describe "hdfs search" do
    let(:model_type) { "hdfs_entry" }
    let(:found_model_text) { hdfs_entries(:searchable).name }
    let(:model_link) { "HDFS Files" }
    it_behaves_like "model specific search"
  end
end