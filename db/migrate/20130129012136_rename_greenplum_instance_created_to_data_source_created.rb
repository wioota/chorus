class RenameGreenplumInstanceCreatedToDataSourceCreated < ActiveRecord::Migration
  def up
    execute "UPDATE events SET action = 'Events::DataSourceCreated' WHERE action='Events::GreenplumInstanceCreated'"
  end

  def down
    execute "UPDATE events SET action = 'Events::GreenplumInstanceCreated' WHERE action='Events::DataSourceCreated'"
  end
end
