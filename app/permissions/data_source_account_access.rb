class DataSourceAccountAccess < DefaultAccess
  def update?(account)
    data_source = account.data_source
    current_user.admin? || !data_source.shared? || data_source.owner_id == account.owner_id
  end
end