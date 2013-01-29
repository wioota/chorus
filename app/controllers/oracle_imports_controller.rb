class OracleImportsController < ApplicationController
  wrap_parameters :oracle_import

  def create
    options = params[:oracle_import]
    #move to queue, transition from schema_id to workspace_id and use its sandbox
    #maybe merge with datasets import controller
    OracleImportExecutor.new({
                                 :user => current_user,
                                 :schema => GpdbSchema.find(options[:schema_id]),
                                 :url => oracle_pipes_url({
                                                              :host => ChorusConfig.instance.public_url,
                                                              :port => ChorusConfig.instance.server_port
                                                          }),
                                 :table_name => options[:table_name]
                             }).run

    render :json => {}, :status => :created
  end
end