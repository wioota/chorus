require 'validator'

namespace :validations do
  desc 'Check Data Sources'
  task :data_source => :environment do
    result = ExistingDataSourcesValidator.run
    if !result
      exit(1)
    end
  end
end