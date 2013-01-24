class GpdbController < ApplicationController
  private

  def authorize_gpdb_data_source_access(resource)
    authorize! :show_contents, resource.gpdb_data_source
  end

  def authorized_gpdb_account(resource)
    authorize_gpdb_data_source_access(resource)
    gpdb_account_for_current_user(resource)
  end

  def gpdb_account_for_current_user(resource)
    resource.gpdb_data_source.account_for_user!(current_user)
  end
end
