class JobTask < ActiveRecord::Base
  include SoftDelete
  ACTIONS = %w( import_source_data run_work_flow run_sql_file )

  attr_accessible :index, :name, :action

  belongs_to :job

  validates :index, :presence => true, :uniqueness => {:scope => [:job_id, :deleted_at]}
  validates_presence_of :name
  validates :action, :presence => true, :inclusion => {:in => ACTIONS }
  validates_presence_of :job

end
