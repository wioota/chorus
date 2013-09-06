require 'net/http'
require 'uri'

module Alpine
  class API
    def self.delete_work_flow(work_flow)
      new.delete_work_flow(work_flow)
    end

    def self.create_work_flow(work_flow, body)
      new.create_work_flow(work_flow, body)
    end

    def self.run_work_flow_task(task)
      user = task.job.owner
      new(user: user).run_work_flow(task.payload, task: task)
    end

    def self.stop_work_flow_task(task)
      user = task.job.owner
      new(user: user).stop_work_flow(task.killable_id)
    end

    # INSTANCE METHODS

    def initialize(options = nil)
      options ||= {}
      @config = options[:config] || ChorusConfig.instance
      @user = options[:user] || User.current_user
    end

    def delete_work_flow(work_flow)
      request_deletion(work_flow) if config.workflow_configured?
    end

    def create_work_flow(work_flow, body)
      request_creation(body, work_flow) if config.workflow_configured?
    end

    def run_work_flow(work_flow, options = {})
      ensure_session
      request_run(work_flow, options) if config.workflow_configured?
    end

    def stop_work_flow(process_id)
      ensure_session
      request_stop(process_id) if config.workflow_configured?
    end

    private

    attr_reader :config, :user

    def ensure_session
      unless Session.not_expired.where(user_id: user.id).present?
        session = Session.new
        session.user = user
        session.save!
      end
    end

    def request_creation(body, work_flow)
      request_base.post(create_path(work_flow), body, {"Content-Type" => "application/xml"})
    end

    def request_deletion(work_flow)
      request_base.delete(delete_path(work_flow))
    rescue SocketError, Errno::ECONNREFUSED, TimeoutError => e
      pa "Unable to connect to an Alpine at #{base_url}. Encountered #{e.class}: #{e}"
    end

    def request_stop(process_id)
      request_base.post(stop_path(process_id), '')
    rescue StandardError => e
      pa "Unable to connect to an Alpine at #{base_url}. Encountered #{e.class}: #{e}"
    end

    def request_run(work_flow, options)
      response = request_base.post(run_path(work_flow, options), '')
      raise StandardError.new(response.body) unless response.code == '200'
      JSON.parse(response.body)['process_id']
    rescue StandardError => e
      pa "Unable to connect to an Alpine at #{base_url}. Encountered #{e.class}: #{e}"
      raise e
    end

    def delete_path(work_flow)
      "/alpinedatalabs/main/chorus.do?method=deleteWorkFlow&session_id=#{session_id}&workfile_id=#{work_flow.id}"
    end

    def create_path(work_flow)
      "/alpinedatalabs/main/chorus.do?method=importWorkFlow&session_id=#{session_id}&file_name=#{work_flow.file_name}&workfile_id=#{work_flow.id}"
    end

    def run_path(work_flow, options)
      params = {
        method: 'runWorkFlow',
        session_id: session_id,
        workfile_id: work_flow.id
      }
      params[:job_task_id] = options[:task].id if options[:task]

      execution_location = work_flow.execution_locations.first
      params.merge!({database_id: execution_location.id}) if execution_location.is_a?(GpdbDatabase)
      params.merge!({hdfs_data_source_id: execution_location.id}) if execution_location.is_a?(HdfsDataSource)

      "/alpinedatalabs/main/chorus.do?#{params.to_query}"
    end

    def stop_path(process_id)
      params = {
        method: 'stopWorkFlow',
        session_id: session_id,
        process_id: process_id
      }
      "/alpinedatalabs/main/chorus.do?#{params.to_query}"
    end

    def base_url
      URI(config.workflow_url)
    end

    def request_base
      Net::HTTP.new(base_url.host, base_url.port)
    end

    def session_id
      Session.not_expired.where(user_id: user.id).first.session_id
    end
  end
end