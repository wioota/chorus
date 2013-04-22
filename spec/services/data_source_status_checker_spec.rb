require 'spec_helper'

describe DataSourceStatusChecker do
  describe '.check_all' do
    before do
      mock(DataSource).find_each { |arg| arg.should be_a(Proc) }
      mock(HdfsDataSource).find_each { |arg| arg.should be_a(Proc) }
    end

    it "works over each data source" do
      DataSourceStatusChecker.check_all
    end
  end
end

