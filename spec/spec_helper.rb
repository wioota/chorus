require 'rubygems'
ENV["RAILS_ENV"] ||= 'test'
ENV["LOG_LEVEL"] = '3'
require File.expand_path("../../config/environment", __FILE__)
require 'sunspot_matchers'
require 'rspec/rails'
require 'rspec/autorun'
require "paperclip/matchers"
require 'rspec_api_documentation'
require 'rspec_api_documentation/dsl'
require 'allowy/rspec'
require 'shoulda-matchers'
require 'factory_girl'

module Shoulda # :nodoc:
  module Matchers
    module ActiveModel # :nodoc:
      module Helpers
        def default_error_message(key, options = {})
          model_name = options.delete(:model_name)
          attribute = options.delete(:attribute)
          [key, options]
        end
      end
    end
  end
end

require 'external_service_detector'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f unless f.match /fixture_builder/ }

# If this offset is not here and you have pre-built fixture_builder, the ids/usernames/etc of new
# models from Factory Girl will clash with the fixtures
FACTORY_GIRL_SEQUENCE_OFFSET = 44444
FactoryGirl.find_definitions

require 'support/fixture_builder'
silence_warnings do
  FACTORY_GIRL_SEQUENCE_OFFSET = 0
end

RSpec.configure do |config|

  config.filter_run_excluding :legacy_migration => true

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:all) do
    self.class.set_fixture_class :events => Events::Base
    self.class.fixtures :all unless self.class.metadata[:legacy_migration]
  end

  config.before(:each) do
    Rails.logger.info "Started test: #{example.full_description}"
  end

  config.after(:each) do
    Rails.logger.info "Finished test: #{example.full_description}"
  end

  config.before :type => :controller do
    request.env['CONTENT_TYPE'] = "application/json"
  end

    # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  config.before do
    Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
  end

  config.after do
    QC::Conn.disconnect
    Sunspot.session = Sunspot.session.original_session if Sunspot.session.is_a? SunspotMatchers::SunspotSessionSpy
    set_current_user nil
  end

  config.include CurrentUserHelpers
  config.include FileHelper
  config.include FakeRelations
  config.include AuthHelper, :type => :controller
  config.include AcceptanceAuthHelper, :api_doc_dsl => :resource
  config.include RocketPants::TestHelper, :type => :controller
  config.include RocketPants::TestHelper, :type => :request
  config.include MockPresenters, :type => :controller
  config.include CustomValidators, :type => :model
  config.include JsonHelper, :type => :controller
  config.include JsonHelper, :type => :request
  config.include FixtureGenerator, :type => :controller
  config.include Paperclip::Shoulda::Matchers
  config.include GpdbTestHelpers
  config.include AllowyRSpecHelpers
  config.include InstanceIntegration, :greenplum_integration => true
  config.include SunspotMatchers
  config.include SolrHelpers
  config.extend ApiDocHelper, :api_doc_dsl => :endpoint
end
