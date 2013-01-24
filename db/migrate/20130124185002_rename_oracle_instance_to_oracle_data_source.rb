class RenameOracleInstanceToOracleDataSource < ActiveRecord::Migration
  def up
    execute "UPDATE data_sources SET type = 'OracleDataSource' WHERE type = 'OracleInstance'"
    execute "UPDATE events SET target1_type = 'OracleDataSource' WHERE target1_type = 'OracleInstance'"
    execute "UPDATE events SET target2_type = 'OracleDataSource' WHERE target2_type = 'OracleInstance'"
  end

  def down
    execute "UPDATE data_sources SET type = 'OracleInstance' WHERE type = 'OracleDataSource'"
    execute "UPDATE events SET target1_type = 'OracleInstance' WHERE target1_type = 'OracleDataSource'"
    execute "UPDATE events SET target2_type = 'OracleInstance' WHERE target2_type = 'OracleDataSource'"
  end
end
