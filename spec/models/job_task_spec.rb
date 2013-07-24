require 'spec_helper'

describe JobTask do
  it { should validate_presence_of :index }
  it { should validate_presence_of :name }
  it { should validate_presence_of :action }
  it { should ensure_inclusion_of(:action).in_array(%w( import_source_data run_work_flow run_sql_file )) }
  it { should validate_presence_of :job }
  it { should belong_to(:job) }

end