class AddUserModifiedAtToWorkfiles < ActiveRecord::Migration
  class MigrationWorkfile < ActiveRecord::Base
    self.table_name = :workfiles
  end

  def up
    add_column :workfiles, :user_modified_at, :datetime

    MigrationWorkfile.all.each do |workfile|
      workfile.user_modified_at = workfile.updated_at
      workfile.save
    end
  end

  def down
    remove_column :workfiles, :user_modified_at
  end
end
