class ChangeDefaultsOnUserAuthMethodLdapGroup < ActiveRecord::Migration
  def up
    change_column :users, :auth_method, :string, :default => nil, :null => true
    change_column :users, :ldap_group_id, :string, :default => nil, :null => true
  end

  def down
    change_column :users, :auth_method, :string, :default => '', :null => true
    change_column :users, :ldap_group_id, :string, :default => '', :null => true
  end
end
