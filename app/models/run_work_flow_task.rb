class RunWorkFlowTask < JobTask

  belongs_to :payload, :class_name => 'AlpineWorkfile'

  def execute
    Alpine::API.run_work_flow_task(self)
    update_attribute(:status, 'running')
    wait_until {
      reload.status == 'finished'
    }
    true
  rescue
    raise JobTask::JobTaskFailure
  ensure
    idle!
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

  def self.sleep_time
    60
  end

  private

  def wait_until
    Timeout::timeout (60*60*12).seconds do
      until yield
        sleep self.class.sleep_time
      end
    end
  end

  def idle!
    self.status = nil
    save!
  end
end