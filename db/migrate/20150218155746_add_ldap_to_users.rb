class AddLdapToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_method, :string, :default => '', :null => true
    add_column :users, :ldap_group_id, :string, :default => '', :null => true
  end
end
