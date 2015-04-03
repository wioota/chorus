class AddIndexConstraintToPermissions < ActiveRecord::Migration
  def change
    add_index :permissions, [:role_id, :chorus_class_id], :unique => true
  end
end
