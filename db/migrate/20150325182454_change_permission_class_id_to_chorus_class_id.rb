class ChangePermissionClassIdToChorusClassId < ActiveRecord::Migration
  def change
    rename_column :permissions, :class_id, :chorus_class_id
  end
end
