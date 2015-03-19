# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
require 'user'

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

dev1 = User.create(
    :username => "developer1",
    :first_name => "Dev",
    :last_name => "1",
    :email => "dev1@example.com",
    :password => "secret",
    :password_confirmation => "secret"
)

dev2 = User.create(
    :username => "developer2",
    :firstname => "Dev",
    :lastname => "2",
    :email => "dev2@example.com",
    :password => "secret",
    :password_confirmation => "secret"
)

dev3 = User.create(
    :username => "developer3",
    :firstname => "Dev",
    :lastname => "3",
    :email => "dev3@example.com",
    :password => "secret",
    :password_confirmation => "secret"
)

data1 = User.create(
    :username => "datascientist1",
    :first_name => "Data",
    :last_name => "Scientist",
    :email => "data1@example.com",
    :password => "secret",
    :password_confirmation => "secret"
)

data2 = User.create(
    :username => "datascientist2",
    :first_name => "Data",
    :last_name => "Scientist",
    :email => "data2@example.com",
    :password => "secret",
    :password_confirmation => "secret"
)


# --- ROLES---

dev_role = Role.create(
    :name => "Developer",
    :descroption => "Developer role"
)
dev_role.users << [dev1, dev2, dev3]

data_scientist_role = Role.create(
    :name => "Data Scientist",
    :description => "Data scientist role"
)
data_scientist_role.users << [data1, data2]

