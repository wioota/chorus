source :rubygems

gem 'rails', '3.2.9.rc1'

gem 'will_paginate'
gem 'net-ldap',      :require => false
gem 'paperclip', '3.0.4'
gem 'queue_classic', :github => "GreenplumChorus/queue_classic"
gem 'clockwork',     :require => false
gem 'allowy'
gem 'sunspot_rails', '2.0.0.pre.120720'
gem 'jetpack', :github => "GreenplumChorus/jetpack", :require => false
gem 'sunspot_solr', '2.0.0.pre.120720'
gem 'nokogiri'
gem 'postgresql_cursor', :github => "GreenplumChorus/postgresql_cursor"
gem 'attr_encrypted'
gem 'tabcmd_gem', :git => "git@github.com:GreenplumChorus/tableau.git"
gem 'chorusgnip', :github => 'GreenplumChorus/gnip'
gem "logger-syslog", git: 'git@github.com:scambra/logger-syslog.git'

platform :jruby do
  gem 'jruby-openssl', :require => false
  # Pull request: https://github.com/jruby/activerecord-jdbc-adapter/pull/207
  gem 'activerecord-jdbcpostgresql-adapter', :github => "GreenplumChorus/activerecord-jdbc-adapter", :branch => "dynamic-schema-search-path"
end

group :assets do
  gem 'sass-rails'
  gem 'compass-rails'
  gem 'handlebars_assets'
  gem 'therubyrhino'
  gem 'uglifier', '>= 1.0.3'
  gem 'yui-compressor'
  gem 'turbo-sprockets-rails3'
end

group :integration do
  gem 'capybara',            :require => false
  gem 'headless'
  gem 'capybara-screenshot'
end

group :test, :integration, :packaging, :ci_jasmine, :ci_legacy_migration do
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
end

group :test, :development, :integration, :packaging, :ci_jasmine, :ci_legacy_migration do
  gem 'foreman', '0.46',         :require => false
  gem 'rake',                    :require => false
  gem 'ruby-debug',              :require => false
  gem 'jasmine'
  gem 'rspec_api_documentation', :github => "GreenplumChorus/rspec_api_documentation"
  gem 'forgery'
  gem 'sunspot_matchers', :github => "pivotal/sunspot_matchers", :branch => "sunspot_2_pre"
  gem 'fixture_builder'
  gem 'ci_reporter'
  gem 'faker'
  gem 'fakeweb'
end

group :development do
  gem 'license_finder'
  gem 'jshint_on_rails'
  gem 'mizuno', :github => "GreenplumChorus/mizuno", :branch => '0.6.4_changes'
  gem 'newrelic_rpm'
end
