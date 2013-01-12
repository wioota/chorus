class OracleInstancesController < ApplicationController
  def create
    instance = current_user.oracle_instances.create!(params, :as => :create)
    present instance, :status => :created
  end
end
