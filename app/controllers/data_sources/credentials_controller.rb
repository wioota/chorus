require 'ipaddr'

module DataSources
  class CredentialsController < ApplicationController
    before_filter :check_work_flow_enabled, :enforce_localhost_only

    def show
      data_source = DataSource.find(params[:data_source_id])
      account = data_source.account_for_user!(current_user)
      present(account, :presenter_options => {:presenter_class => :CredentialsPresenter})
    end

    private

    def check_work_flow_enabled
      head :not_found unless ChorusConfig.instance.work_flow_configured?
    end

    def enforce_localhost_only
      head :not_found unless address_local?(request.remote_ip) && address_local?(request.remote_addr)
    end

    def address_local?(ip)
      local_addresses = ActionDispatch::Request::LOCALHOST + ['::ffff:127.0.0.1']
      local_addresses.any? {|local_addr_pattern| local_addr_pattern === ip }
    end
  end
end