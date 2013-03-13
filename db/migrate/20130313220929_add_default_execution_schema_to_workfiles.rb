class AddDefaultExecutionSchemaToWorkfiles < ActiveRecord::Migration
  class Workfile < ActiveRecord::Base
    belongs_to :workspace
  end

  class Workspace < ActiveRecord::Base
  end

  def up
    Workfile.where(:type => 'ChorusWorkfile').where(:content_type => 'sql').where('execution_schema_id IS NULL AND deleted_at IS NULL').each do |workfile|
      workfile.execution_schema_id = workfile.workspace.sandbox_id
      workfile.save!
    end
  end

  def down
  end
end
