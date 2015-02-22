class AddTableauSite < ActiveRecord::Migration
  def change
    add_column :tableau_workbook_publications, :site_name, :string, :default => "Default", :null => true
  end
end
