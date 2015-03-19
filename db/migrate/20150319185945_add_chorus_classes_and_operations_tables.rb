class AddChorusClassesAndOperationsTables < ActiveRecord::Migration
  def change
    create_table :chorus_classes do |t|
      t.string :name, :null => false
      t.string :description
      t.integer :parent_class_id
      t.string :parent_class_name

      t.timestamps
    end

    create_table :operations do |t|
      t.integer :chorus_class_id
      t.string :name, :null => false
      t.string :description

      t.timestamps
    end

    rename_column :chorus_objects, :class_id, :chorus_class_id
  end
end
