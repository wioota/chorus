class TableauWorkbookPublication < ActiveRecord::Base
  attr_accessible :dataset_id, :name, :workspace_id, :site_name, :project_name

  belongs_to :dataset, :touch => true
  belongs_to :workspace, :touch => true
  belongs_to :linked_tableau_workfile, :touch => true

  after_create :create_created_event

  def workbook_url
    "http://#{base_url}/workbooks/#{name}"
  end

  def project_url
    "http://#{base_url}/workbooks?fe_project.name=#{project_name}"
  end

  def base_url
    base_url = ChorusConfig.instance['tableau.url']
    port = ChorusConfig.instance['tableau.port']
    base_url += ":#{port}" if !port.nil? && port != 80
    base_url += "/t/#{site_name}" if !base_url.nil? && !site_name.nil? && site_name != 'Default'
    base_url
  end

  private

  def create_created_event
    Events::TableauWorkbookPublished.by(current_user).add(
        :workbook_name => name,
        :dataset => dataset,
        :workspace => workspace,
        :workbook_url => workbook_url,
        :project_name => project_name,
        :site_name => site_name,
        :project_url => project_url
    )
  end
end
