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
gem 'addressable'
gem 'sentry-raven'
gem 'racksh'
gem 'warning'
gem 'rake'
gem 'rubocop', '~> 1.40.0', require: false
gem 'pry'
gem 'dyno_metadata'

group :development do
  gem 'foreman'
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
