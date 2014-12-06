require_relative '../task_helpers/validators/existing_data_sources_validator'
require_relative '../task_helpers/validators/used_ports_validator'
require_relative '../task_helpers/validators/chorus_license_validator'

namespace :validations do
  desc 'Check Data Sources'
  task :data_source => :environment do
    legacy_gpdb_instance = Class.new(ActiveRecord::Base) do
      table_name = 'gpdb_instances'
    end

    data_valid = ExistingDataSourcesValidator.run([
      legacy_gpdb_instance,
      DataSource,
      HdfsDataSource,
      GnipDataSource
    ])

    exit(1) unless data_valid
  end

  desc 'Check Used Network Ports'
  task :check_ports do
    required_ports = [3000, 5432, 8080]
    ports_valid = UsedPortsValidator.run(required_ports)

    exit(1) unless ports_valid
  end

  desc 'Check Chorus license validity'
  task :chorus_license do
    chorus_license = License.new
    license_valid = ChorusLicenseValidator.run(chorus_license)
    exit(1) unless license_valid
  end

  task :all => [:data_source, :check_ports, :chorus_license]
end
