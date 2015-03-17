class AddTablesForRolesGroupsAndPermissions < ActiveRecord::Migration
  def change

    create_table :groups do |t|
      t.string :name, :null => false
      t.string :description

      t.timestamps
    end

    create_table :scopes do |t|
      t.string :name, :null => false
      t.string :description
      t.integer :group_id

      t.timestamps
    end

    create_table :objects do |t|
      t.string :class_id, :null => false
      t.string :instance_id, :null => false
      t.string :parent_class_id
      t.string :parent_class_name
      t.integer :permissions_mask

      t.timestamps
    end

    create_table :roles do |t|
      t.string :name, :null => false
      t.string :description

      t.timestamps
    end

    create_table :permissions do |t|
      t.integer :role_id, :null => false
      t.string :class_id, :null => false
      t.integer :permissions_mask

      t.timestamps
    end

    # create_join_table :groups, :users
    create_table :groups_users, :id => false do |t|
      t.integer :group_id
      t.integer :user_id
    end
    add_index :groups_users, [:group_id, :user_id]

    # create_join_table :groups, :roles
    create_table :groups_roles, :id => false do |t|
      t.integer :group_id
      t.integer :role_id
    end
    add_index :groups_roles, [:group_id, :role_id]

    # create_join_table :users, :roles
    create_table :roles_users, :id => false do |t|
      t.integer :role_id
      t.integer :user_id
    end
    add_index :roles_users, [:role_id, :user_id]

  end
end
