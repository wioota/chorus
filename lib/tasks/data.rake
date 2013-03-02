require 'duplicate_schema_validator'

namespace :data do
  desc 'Merge duplicate Schemas'
  task :merge_duplicate_schemas => :environment do
    puts "Merging duplicated Schemas..."
    DuplicateSchemaValidator.logger = Logger.new(STDOUT)
    DuplicateSchemaValidator.run_and_fix
  end
end
