class MoveWorkfileDatabaseIdToExecutionLocation < ActiveRecord::Migration

  class MigrationWorkfile < ActiveRecord::Base
    self.table_name = :workfiles
    serialize :additional_data, JsonHashSerializer
  end

  def up
    MigrationWorkfile.where(type: 'AlpineWorkfile').find_each do |wf|
      database_id = wf.additional_data['database_id']
      if database_id && wf.execution_location_id.nil?
        p "Setting AlpineWorkfile #{wf.id} execution_location to GpdbDatabase #{database_id}."
        wf.execution_location_id = database_id
        wf.additional_data.delete 'database_id'
        wf.save!
      end
    end
  end

  def down
    MigrationWorkfile.where(type: 'AlpineWorkfile').find_each do |wf|
      wf.additional_data['database_id'] = wf.execution_location_id if wf.execution_location_id
      wf.save!
    end
  end
end
