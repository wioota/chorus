class AddUniqueContraintToSchemasNames < ActiveRecord::Migration
  def change
    add_index :schemas, [:name, :parent_id, :parent_type], :unique => true
  end
end
