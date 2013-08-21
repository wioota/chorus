class PopulateJobTaskResultType < ActiveRecord::Migration
  class JobTaskResult < ActiveRecord::Base; end

  def up
    JobTaskResult.find_each do |result|
      if result.name.start_with?('Run')
        result.type = 'RunWorkFlowTaskResult'
      else
        result.type = 'ImportSourceDataTaskResult'
      end
      result.save
    end
  end
end
