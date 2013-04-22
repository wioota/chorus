class DataSourceStatusChecker
  def self.check_all
    DataSource.find_each(&:check_status!)
    HdfsDataSource.find_each(&:check_status!)
  end

  def self.check(data_source)
    data_source.check_status!
  end
end