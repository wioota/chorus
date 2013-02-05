ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require "paperclip/matchers"
require 'shoulda-matchers'
require 'database_cleaner'

DatabaseCleaner.strategy = :truncation

SPEC_WORKFILE_PATH = Rails.root + "system/legacy_workfiles"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f unless f.match /fixture_builder/ }

RSpec.configure do |config|
  config.mock_with :rr

  config.before(:suite) do
    DatabaseCleaner.clean

    def legacy_sql_md5
      '0b8638a9e2d4cb5ed9f3b1a35d25bb35'
    end

    unless File.exist?("db/legacy/legacy_#{legacy_sql_md5}.sql")
      p "Downloading legacy dump from server"
      FileUtils.mkdir_p('db/legacy')
      `wget -O db/legacy/legacy_#{legacy_sql_md5}.sql http://greenplum-ci.sf.pivotallabs.com/~ci/legacy_#{legacy_sql_md5}.sql`
    end

    Dir.chdir Rails.root do
      # using system below seems to cause the script to hang
      result = `spec/legacy_migrate_schema_setup.sh db/legacy/legacy_#{legacy_sql_md5}.sql #{ActiveRecord::Base.connection.current_database}`
      raise "legacy migration failed:\n#{result}" unless $?.success?
    end

    any_instance_of(WorkfileMigrator::LegacyFilePath) do |p|
      # Stub everything with a text file so paperclip doesn't blow up
      stub(p).path { Rails.root.join "spec/fixtures/some.txt" }
    end

    # quiet the tests
    stub(AbstractMigrator).log.with_any_args

    # run all migrations
    DataMigrator.migrate_all SPEC_WORKFILE_PATH
  end

  config.after(:suite) do
    #`psql -p 8543 chorus_rails_test -c 'drop schema if exists legacy_migrate cascade'`
  end

  config.include FileHelper
  config.include FakeRelations
end

def clear_events_and_associations
  # Because the tables are not cleaned up after every test,
  # the InOrderEventMigrator and ActivityMigrator both need to have this run beforehand
  # otherwise they will use each other's data.
  Legacy.connection.exec_query("DELETE FROM events;")
  Legacy.connection.exec_query("DELETE FROM notifications;")
  Legacy.connection.exec_query("DELETE FROM comments;")
  Legacy.connection.exec_query("DELETE FROM activities;")
end
