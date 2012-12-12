require 'factory_girl'

FactoryGirl.define do
  factory :comment do
    event factory: :user_created_event
    author factory: :user
    body 'this is a comment'
  end

  factory :insight, :parent => :note_on_workspace_event do
    insight true
  end

  factory :csv_file do
    workspace
    user
    truncate false
    to_table 'some_new_table'
    column_names ['id', 'body']
    types ['text', 'text']
    delimiter ','
  end
end