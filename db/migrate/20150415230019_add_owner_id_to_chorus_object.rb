class AddOwnerIdToChorusObject < ActiveRecord::Migration
  def change
    add_column :chorus_objects, :owner_id, :integer
  end
end
