class OracleInstancesController < ApplicationController
  def create
    #instance = OracleInstance.create!(params)
    instance = Oracle::InstanceRegistrar.create!(params, current_user)
    present instance, :status => :created
  end
end
