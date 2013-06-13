require 'net/http'
require 'uri'

module Alpine
  module API
    def self.delete_work_flow(work_flow)
      return unless ChorusConfig.work_flow_configured?

      request = Net::HTTP::Delete.new(delete_path(work_flow))

      Net::HTTP.new(base_url).request(request)
    rescue SocketError => e
      pa "Unable to connect to an Alpine at #{base_url}. Encountered #{e.class}: #{e}"
    end

    private

    def self.delete_path(work_flow)
      "/alpinedatalabs/main/chorus.do?method=deleteWorkFlow&session_id=#{session_id}&workfile_id=#{work_flow.id}"
    end

    def self.base_url
      ChorusConfig.instance['work_flow.url']
    end

    def self.session_id
      session = Session.find_by_user_id(User.current_user.id)
      session.session_id
    end
  end
end