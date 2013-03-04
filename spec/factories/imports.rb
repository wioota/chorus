require 'factory_girl'

FactoryGirl.define do
  factory :import_schedule do
    start_datetime Time.current
    end_date Time.current + 1.year
    frequency 'monthly'
    truncate false
    new_table true
    sample_count 1
    association :workspace
    association :user
    sequence(:to_table) { |n| "factoried_import_schedule_table#{n}" }
    association :source_dataset, factory: :gpdb_table
  end

  factory :abstract_import, class: Import do
    created_at Time.current
    association :source_dataset, factory: :gpdb_table
    user
    sequence(:to_table) { |n| "factoried_import_table#{n}" }
    truncate false
    new_table true
    sample_count 10
    file_name nil

    factory :import, class: WorkspaceImport do
      association :workspace, factory: :workspace
    end

    factory :schema_import, class: SchemaImport do
      association :schema, factory: :gpdb_schema
    end
  end

  factory :import_with_schedule, parent: :import do
    association :import_schedule
  end

  factory :csv_import, class: WorkspaceImport do
    created_at Time.current
    association :workspace, factory: :workspace
    association :destination_dataset, factory: :gpdb_table
    user
    file_name "import.csv"
    sequence(:to_table) { |n| "factoried_import_table#{n}" }
    truncate false
    new_table true
    sample_count 10
  end
end