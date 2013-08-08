class RunWorkFlowTask < JobTask
  belongs_to :payload, :class_name => 'AlpineWorkfile'

  def execute
    Alpine::API.run_work_flow payload
    true
  end

  def attach_payload(params)
    self.payload = AlpineWorkfile.find params[:work_flow_id]
  end

  def build_task_name
    self.name = "Run #{payload.file_name}"
  end

  def update_attributes(params)
    attach_payload(params) if params[:work_flow_id]
    super
  end
end