require 'validator'

namespace :validations do
  desc 'Check Data Sources'
  task :data_source => :environment do
    #if !Validator.valid?
    #  exit(1)
    #end
  end
end