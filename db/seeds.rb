# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
FACTORY_GIRL_SEQUENCE_OFFSET = 44444
require 'user'
require 'factory_girl'
require 'spec/factories/users.rb'
require 'spec/factories/roles_groups_permissions.rb'
require 'spec/factories/factories.rb'

ActiveRecord::Base.connection.schema_cache.clear!

class BlackholeSession
  def initialize(*args)
  end

  def method_missing(*args)
  end
end

Sunspot.session = BlackholeSession.new

# --- USERS ---

unless User.where(:username => "chorusadmin").present?
  puts "Creating chorusadmin user..."
  user = User.new(
    :username => "chorusadmin",
    :first_name => "Chorus",
    :last_name => "Admin",
    :email => "chorusadmin@example.com",
    :password => "secret",
    :password_confirmation => "secret"
  )
  user.admin = true
  user.save!
end
chorusadmin = User.find_by_username("chorusadmin")

dev_workspace1 = FactoryGirl.create(:workspace, :name => "Development workspace one")
mark_workspace1 = FactoryGirl.create(:workspace, :name => "Marketing workspace one")

data_source_info = {
  "name"=>"PG DB",
   "description"=>"",
   "host"=>"10.0.0.168",
   "port"=>"5432",
   "db_name"=>"postgres",
   "db_username"=>"miner_demo",
   "db_password"=>"miner_demo",
   "ssl"=>false,
   "shared"=>false,
   "high_availability"=>false,
   "hive_kerberos"=>false
}

pg_data_source= DataSource.create_for_entity_type("pg_data_source", chorusadmin, data_source_info)
pg_data_source= DataSource.create_for_entity_type("pg_data_source", chorusadmin, data_source_info.merge({"name" => "Other PG DB"}))
#chorus_objects = [dev_workspace1, pg_data_source, mark_workspace1]
chorus_objects = [dev_workspace1, mark_workspace1]

# --- ROLES GROUPS PERMISSIONS ---

# --- administrator users and role ---
admin = FactoryGirl.create(:user, :username => "admin")
admin_role = FactoryGirl.create(:role, :name => "Admin")
admin_role.users << [admin, chorusadmin]

# --- developer users and role ---
#dev1 = FactoryGirl.create(:user, :username => "dev1")
dev1 = User.create(
  :username => "dev1",
  :first_name => "dev",
  :last_name => "1",
  :email => "dev1@example.com",
  :password => "secret",
  :password_confrmation => "secret"
)
dev2 = FactoryGirl.create(:user, :username => "dev2")
dev_role = FactoryGirl.create(:role, :name => "Developer")
dev_role.users << [dev1, dev2]

# --- collaborator users and role ---
collab1 = User.create(
  :username => "collab1",
  :first_name => "collab",
  :last_name => "1",
  :email => "collab1@example.com",
  :password => "secret",
  :password_confirmation => "secret"
)
collab2 = FactoryGirl.create(:user, :username => "collab2")
collab_role = FactoryGirl.create(:role, :name => "Collaborator", :description => "Role for collaborator")
collab_role.users << [collab1, collab2]

# --- objects and classes for developer role ---
chorus_objects.each do |obj|
  chorus_class = ChorusClass.find_or_create_by_name(obj.class.name)
  chorus_object = chorus_class.chorus_objects.find_or_create_by_instance_id(obj.id)
  puts "Adding #{chorus_object} to #{chorus_class}"
end

# --- PERMISSIONS ---


Workspace.create_permissions_for collab_role, [:show]
Workspace.create_permissions_for dev_role, [:show, :update]
Workspace.create_permissions_for admin_role, [:show, :update, :destroy]

DataSource.create_permissions_for [dev_role, admin_role], [:edit]

