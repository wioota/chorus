class DataSourceAccess < DefaultAccess
  def self.data_sources_for(current_user)
    DataSource.accessible_to(current_user)
  end

  def show?(data_source)
    true
  end

  def edit?(data_source)
    data_source.owner == current_user || current_user.admin?
  end

  def show_contents?(data_source)
    data_source.shared? || current_user.instance_accounts.exists?(:instance_id => data_source.id)
  end
end

class GpdbInstanceAccess < DataSourceAccess
end