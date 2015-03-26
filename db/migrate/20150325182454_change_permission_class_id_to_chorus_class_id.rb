class ChangePermissionClassIdToChorusClassId < ActiveRecord::Migration
  def up
    rename_column :permissions, :class_id, :chorus_class_id
    change_column :permissions, :chorus_class_id, 'integer USING CAST("chorus_class_id" AS integer)'
  end

  def down
    change_column :permissions, :chorus_class_id, :string
    rename_column :permissions, :chorus_class_id, :class_id
  end
end
