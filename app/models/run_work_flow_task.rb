class RunWorkFlowTask < JobTask
  has_additional_data :work_flow_id

  def self.assemble!(params, job)
    task = RunWorkFlowTask.new(params)
    task.job = job
    task.save!
    task
  end

  def execute
    true
  end

  def work_flow
    AlpineWorkfile.find(work_flow_id)
  end
end