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

    private

    attr_reader :config, :user

    def request_creation(body, work_flow)
      request_base.post(create_path(work_flow), body)
    rescue SocketError, Errno::ECONNREFUSED, TimeoutError => e
      pa "Unable to connect to an Alpine at #{base_url}. Encountered #{e.class}: #{e}"
    end

    def request_deletion(work_flow)
      request_base.delete(delete_path(work_flow))
    rescue SocketError, Errno::ECONNREFUSED, TimeoutError => e
      pa "Unable to connect to an Alpine at #{base_url}. Encountered #{e.class}: #{e}"
    end

    def delete_path(work_flow)
      "/alpinedatalabs/main/chorus.do?method=deleteWorkFlow&session_id=#{session_id}&workfile_id=#{work_flow.id}"
    end

    def create_path(work_flow)
      "/alpinedatalabs/main/chorus.do?method=createWorkFlow&session_id=#{session_id}&file_name=#{work_flow.file_name}"
    end

    def base_url
      URI(config['work_flow.url'])
    end

    def request_base
      Net::HTTP.new(base_url.host, base_url.port)
    end

    def session_id
      Session.find_by_user_id(user.id).session_id
    end
  end
end