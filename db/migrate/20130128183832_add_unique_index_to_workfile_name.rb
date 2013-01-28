class AddUniqueIndexToWorkfileName < ActiveRecord::Migration
  def change
    add_index :workfiles, [:file_name, :workspace_id], :unique => true
  end
end
