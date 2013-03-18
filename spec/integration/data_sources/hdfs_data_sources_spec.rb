require_relative '../spec_helper'

describe 'Data Sources', :hdfs_integration do
  describe 'adding a hadoop data source' do
    include DataSourceHelpers

    before do
      login(users(:admin))
      visit('#/data_sources')
      click_button 'Add Data Source'
    end

    it 'creates an hadoop data source' do
      within_modal do
        select_and_do_within_data_source 'register_existing_hdfs' do
          fill_in 'name', :with => 'BestHadoop'
          fill_in 'host', :with => WEBPATH['hdfs_data_source_db']['host']
          fill_in 'port', :with => WEBPATH['hdfs_data_source_db']['port']
          fill_in 'username', :with => WEBPATH['hdfs_data_source_db']['username']
          fill_in 'groupList', :with => WEBPATH['hdfs_data_source_db']['group_list']
        end
        click_button "Add Data Source"
      end

      find('.hdfs_data_source ul').should have_content('BestHadoop')
    end
  end
end