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
      user = task.payload.workspace.owner
      new(user: user).run_work_flow(task.payload, task: task)
    end

    def self.run_work_flow(work_flow)
      user = work_flow.workspace.owner
      new(user: user).run_work_flow(work_flow)
    end

    # INSTANCE METHODS

    def initialize(options = nil)
      options ||= {}
      @config = options[:config] || ChorusConfig.instance
      @user = options[:user] || User.current_user
    end

    def delete_work_flow(work_flow)
      request_deletion(work_flow) if config.work_flow_configured?
    end

    def create_work_flow(work_flow, body)
      request_creation(body, work_flow) if config.work_flow_configured?
    end

    def run_work_flow(work_flow, options = {})
      unless Session.not_expired.where(user_id: user.id).present?
        session = Session.new
        session.user = user
        session.save!
      end
      request_run(work_flow, options) if config.work_flow_configured?
    end

    private

    attr_reader :config, :user

    def request_creation(body, work_flow)
      request_base.post(create_path(work_flow), body, {"Content-Type" => "application/xml"})
    end

    def request_deletion(work_flow)
      request_base.delete(delete_path(work_flow))
    rescue SocketError, Errno::ECONNREFUSED, TimeoutError => e
      pa "Unable to connect to an Alpine at #{base_url}. Encountered #{e.class}: #{e}"
    end

    def request_run(work_flow, options)
      response = request_base.post(run_path(work_flow, options), '')
      raise StandardError unless response.code == '200'
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
      params.merge!({database_id: work_flow.execution_location_id}) if work_flow.execution_location_type == 'GpdbDatabase'
      params.merge!({hdfs_data_source_id: work_flow.execution_location_id}) if work_flow.execution_location_type == 'HdfsDataSource'

      "/alpinedatalabs/main/chorus.do?#{params.to_query}"
    end

    def base_url
      URI(config['work_flow.url'])
    end

    def request_base
      Net::HTTP.new(base_url.host, base_url.port)
    end

    def session_id
      Session.not_expired.where(user_id: user.id).first.session_id
    end
  end
end