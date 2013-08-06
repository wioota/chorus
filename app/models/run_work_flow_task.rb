class RunWorkFlowTask < JobTask
  belongs_to :payload, :class_name => 'AlpineWorkfile'

  def execute
    true
  end

  def attach_payload(params)
    self.payload = AlpineWorkfile.find params[:work_flow_id]
  end
end