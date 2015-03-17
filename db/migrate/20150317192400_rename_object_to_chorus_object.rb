class RenameObjectToChorusObject < ActiveRecord::Migration
  def change
    rename_table :objects, :chorus_objects
  end
end
