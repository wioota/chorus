class CreateChorusObjectRolesTable < ActiveRecord::Migration
  def change
    create_table :chorus_object_roles do |t|
      t.integer :chorus_object_id
      t.integer :user_id
      t.integer :role_id

      t.timestamps
    end
  end
end
