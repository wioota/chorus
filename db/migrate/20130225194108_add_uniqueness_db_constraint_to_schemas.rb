class AddUniquenessDbConstraintToSchemas < ActiveRecord::Migration
  def up
    add_index :schemas, [:parent_id, :parent_type, :name], :unique => true
  end

  def down
    remove_index :schemas, :column => [:parent_id, :parent_type, :name]
  end
end
