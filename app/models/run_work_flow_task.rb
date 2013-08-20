class RunWorkFlowTask < JobTask

  belongs_to :payload, :class_name => 'AlpineWorkfile'

  def perform
    result = JobTaskResult.create(:started_at => Time.current, :name => build_task_name)
    Alpine::API.run_work_flow_task(self)
    update_attribute(:status, JobTask::RUNNING)
    wait_until { finished? }
    result.finish :status => JobTaskResult::SUCCESS, :payload_id => payload.id, :payload_result_id => payload_result_id
  rescue StandardError => e
    result.finish :status => JobTaskResult::FAILURE, :message => e.message
  ensure
    idle!
  end

  def attach_payload(params)
    self.payload = AlpineWorkfile.find params[:work_flow_id]
  end

  def build_task_name
    "Run #{payload.file_name}"
  end

  def update_attributes(params)
    attach_payload(params) if params[:work_flow_id]
    super
  end

  def self.sleep_time
    60
  end

  def kill
    #Need a way to reference the current work flow running
  end

  private

  def finished?
    reload.status == JobTask::FINISHED
  end

  def wait_until
    Timeout::timeout (60*60*12).seconds do
      until yield
        sleep self.class.sleep_time
      end
    end
  end
end