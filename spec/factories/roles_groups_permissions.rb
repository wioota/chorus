require 'factory_girl'

FactoryGirl.define do
  factory :role do
    name "role"
    description "This is a description of a role. Here it is! Right here"

    factory :role_with_users do
      after(:create) do |role|
        10.times do |i|
          role.users << create(:user, :username => "role_user#{i}", :first_name => "Role", :last_name => "User")
        end
      end
    end
  end

end
