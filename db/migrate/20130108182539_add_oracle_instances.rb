class AddOracleInstances < ActiveRecord::Migration
  def change
    create_table :oracle_instances do |t|
      t.integer :id
      t.string :name
      t.text :description
      t.string :host
      t.integer :port
      t.string :db_name
    end
  end
end
