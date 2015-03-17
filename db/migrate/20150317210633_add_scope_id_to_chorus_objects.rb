class AddScopeIdToChorusObjects < ActiveRecord::Migration
  def change
    add_column :chorus_objects, :scope_id, :integer
  end
end
