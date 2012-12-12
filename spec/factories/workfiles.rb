require 'factory_girl'

FactoryGirl.define do
  factory :workfile do
    owner
    workspace
    description 'A nice description'
    file_name 'workfile.doc'
  end

  factory :workfile_version do
    workfile
    version_num '1'
    owner
    commit_message 'Factory commit message'
    modifier
  end

  factory :workfile_draft do
    owner
    workfile
    content 'Excellent content'
  end

end
