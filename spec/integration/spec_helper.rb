ENV["RAILS_ENV"] = 'integration'
ENV["LOG_LEVEL"] = '3'

require File.expand_path("../../../config/environment", __FILE__)

require 'rspec/rails'
require 'capybara/rspec'
require 'headless'
require 'yaml'
require 'timeout'
require 'capybara/poltergeist'
require 'factory_girl'
require 'database_cleaner'

headless = Headless.new
headless.start

Capybara.app = Rails.application
Capybara.default_driver = :selenium
Capybara.run_server = true #Whether start server when testing
Capybara.server_port = 8200
Capybara.save_and_open_page_path = ENV['WORKSPACE']
Capybara.default_wait_time = 20

DatabaseCleaner.strategy = :truncation

WEBPATH = YAML.load_file("spec/integration/webpath.yml") unless defined? WEBPATH

def run_jobs_synchronously
  stub(QC.default_queue).enqueue_if_not_queued.with_any_args do |class_and_message, *args|
    p "Running job #{class_and_message}(#{args}) synchronously for test..."
    className, message = class_and_message.split(".")
    className.constantize.send(message, *args)
  end
end

Dir[File.join(File.dirname(__FILE__), 'helpers', "**", "*")].each {|f| require f}
Dir[File.join(File.dirname(__FILE__), 'support', "**", "*")].each {|f| require f}
FACTORY_GIRL_SEQUENCE_OFFSET = 44444
FactoryGirl.find_definitions
require "#{Rails.root}/spec/support/fixture_builder.rb"
require Rails.root.join('spec/external_service_detector.rb').to_s

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.start

    Rails.logger.info "Started test: #{example.full_description}"
  end

  config.after(:each) do
    unless page.has_selector?(".main_content")
      puts "Could not find .main_content in #{example.full_description}"
    end
    unless page.has_no_selector?(".loading_section")
      puts "Incorrectly found .main_content in #{example.full_description}"
    end

    (0..10).each do |counter|
      break unless (page.evaluate_script("$.active != 0") rescue nil)
      sleep 1

      puts "Waiting for AJAX in #{example.full_description}" if counter == 0
      puts "Giving up on outstanding AJAX request for #{example.full_description}" if counter == 10
    end

    begin
      Capybara.reset_sessions! # this should surface unhandled server errors
    ensure
      Rails.logger.info "Finished test: #{example.full_description}"
    end

    DatabaseCleaner.clean
  end

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.mock_with :rr
  config.fixture_path = "#{Rails.root}/spec/integration/fixtures"
  config.use_transactional_fixtures = false
  config.global_fixtures = :all
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers

  config.include LoginHelpers
  config.include CleditorHelpers
  config.include GreenplumIntegration, :greenplum_integration => true
  config.include OracleIntegration, :oracle_integration => true
  config.include HdfsIntegration, :hadoop_integration => true
  config.include CapybaraHelpers
end

# capybara-screenshot must be included after the rspec after hook calling Capybara.reset_sessions! (see above)
# because rspec runs the hooks in reversed order and cannot take a screenshot after resetting the session
require 'capybara-screenshot/rspec'