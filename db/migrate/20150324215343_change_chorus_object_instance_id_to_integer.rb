class ChangeChorusObjectInstanceIdToInteger < ActiveRecord::Migration
  def up
    change_column :chorus_objects, :instance_id, 'integer USING CAST("instance_id" AS integer)'
    change_column :chorus_objects, :chorus_class_id, 'integer USING CAST("chorus_class_id" AS integer)'
  end

  def down
    change_column :chorus_objects, :instance_id, :string
    change_column :chorus_objects, :chorus_class_id, :string
  end
end
