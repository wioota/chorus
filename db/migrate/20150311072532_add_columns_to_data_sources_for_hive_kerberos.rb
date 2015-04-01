class AddColumnsToDataSourcesForHiveKerberos < ActiveRecord::Migration
  def up
    add_column :data_sources, :hive, :boolean, :default => false
    add_column :data_sources, :hive_kerberos, :boolean, :default => false
    add_column :data_sources, :hive_kerberos_principal, :string, :default => '', :null => false
    add_column :data_sources, :hive_kerberos_keytab_location, :string, :default => '', :null => false
    add_column :data_sources, :hive_hadoop_version, :string, :default => '', :null => false
  end

  def down
    remove_column :data_sources, :hive, :boolean, :default => false
    remove_column :data_sources, :hive_kerberos, :boolean, :default => false
    remove_column :data_sources, :hive_kerberos_principal, :string, :default => '', :null => false
    remove_column :data_sources, :hive_kerberos_keytab_location, :string, :default => '', :null => false
    remove_column :data_sources, :hive_hadoop_version, :string, :default => '', :null => false
  end
end
