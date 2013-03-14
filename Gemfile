source 'https://rubygems.org'

gem 'rails', '3.2.11'

gem 'will_paginate'
gem 'net-ldap',      :require => false
gem 'paperclip', '3.0.4'
gem 'queue_classic', :github => "GreenplumChorus/queue_classic"
gem 'clockwork',     :require => false
gem 'allowy'
gem 'sunspot_rails', '2.0.0.pre.120720'
gem 'sunspot_solr', :github => 'taktsoft/sunspot' # https://github.com/sunspot/sunspot/pull/267
gem 'jetpack', :github => "GreenplumChorus/jetpack", :require => false
gem 'nokogiri'
gem 'postgresql_cursor', :github => "GreenplumChorus/postgresql_cursor"
gem 'sequel', :require => 'sequel/no_core_ext'
gem 'attr_encrypted' #if you load attr_encrypted before sequel, it blows up saying 'sequel::model' is undefined
gem 'tabcmd_gem', :github => "GreenplumChorus/tableau"
gem 'chorusgnip', :github => 'GreenplumChorus/gnip'
gem "logger-syslog", :github => 'scambra/logger-syslog'
gem 'newrelic_rpm'

platform :jruby do
  gem 'jruby-openssl', :require => false
  gem 'activerecord-jdbcpostgresql-adapter'
end

group :assets do
  gem 'sass-rails'
  gem 'compass-rails'
  gem 'handlebars_assets'
  gem 'therubyrhino'
  gem 'uglifier'
  gem 'yui-compressor'
  gem 'turbo-sprockets-rails3'
end

group :integration do
  gem 'capybara', "~> 2.0.0", :require => false
  gem 'headless'
  gem 'capybara-screenshot'
end

group :test, :integration, :packaging, :ci_jasmine, :ci_legacy_migration do
  gem 'rspec', :require => false
  gem 'rr'
  gem 'fuubar'
  gem 'factory_girl'
  gem 'shoulda-matchers',    :require => false
  gem 'rspec-rails'
  gem 'journey'
  gem 'timecop'
  gem 'hashie'
  gem 'vcr'
  gem 'fakefs',              :require => false
  gem 'chunky_png'
  gem 'database_cleaner',    :require => false
  gem 'poltergeist', :github => "brutuscat/poltergeist"
  gem 'rspec_api_documentation', :github => "GreenplumChorus/rspec_api_documentation"
end

group :test, :development, :integration, :packaging, :ci_jasmine, :ci_legacy_migration do
  gem 'foreman', '0.46',         :require => false
  gem 'rake',                    :require => false
  gem 'ruby-debug',              :require => false
  gem 'jasmine', :github => 'pivotal/jasmine-gem'
  gem 'forgery'
  gem 'sunspot_matchers', :github => "pivotal/sunspot_matchers", :branch => "sunspot_2_pre"
  gem 'fixture_builder', :github => "rdy/fixture_builder"
  gem 'ci_reporter', '>= 1.8.2'
  gem 'faker'
  gem 'fakeweb'
  gem 'jshint_on_rails'
end

group :development do
  gem 'license_finder'
  gem 'mizuno', :github => "GreenplumChorus/mizuno", :branch => '0.6.4_changes'
  gem 'bullet'
end
