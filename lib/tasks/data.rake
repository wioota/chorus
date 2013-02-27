require 'duplicate_schema_validator'

namespace :data do
  desc 'Merge duplicate Schemas'
  task :merge_duplicate_schemas => :environment do
    puts "Merging duplicated Schemas..."
    DuplicateSchemaValidator.run_and_fix
    puts "Checking for any remaining duplicate Schemas..."
    exit(1) unless DuplicateSchemaValidator.run
  end
end
