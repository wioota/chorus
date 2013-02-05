module DataSourceAuth
  extend ActiveSupport::Concern

  def authorize_data_source_access(resource)
    authorize! :show_contents, resource.data_source
  end

  def authorized_account(resource)
    authorize_data_source_access(resource)
    account_for_current_user(resource)
  end

  def account_for_current_user(resource)
    resource.data_source.account_for_user!(current_user)
  end
end