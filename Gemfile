# frozen_string_literal: true

source 'https://rubygems.org/'
ruby File.read('.ruby-version').chomp

gem 'sequel'
gem 'pg'
gem 'sequel_pg', require: 'sequel'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'rack-flash3', require: 'rack-flash'
gem 'haml'
gem 'puma'
gem 'spinels-rack-ssl-enforcer'
gem 'html-pipeline'
gem 'github-markup'
gem 'commonmarker'
gem 'rest-client'
gem 'octokit'
gem 'faraday-retry'
gem 'addressable'
gem 'sentry-ruby'
gem 'racksh'
gem 'warning'
gem 'rake'
gem 'rubocop', '~> 1.57.2', require: false
gem 'dyno_metadata'

group :development do
  gem 'overman'
  gem 'localhost'
end

group :test do
  gem 'climate_control'
  gem 'm'
  gem 'minitest'
  gem 'rack-test'
  gem 'wait_for_it'
  gem 'webmock'
end
