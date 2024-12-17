# frozen_string_literal: true

source 'https://rubygems.org/'
ruby file: '.ruby-version'

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
# Until the :default_gem_removal PR is released (warning >1.4.0)
# https://github.com/jeremyevans/ruby-warning/pull/24
gem 'warning', github: 'jeremyevans/ruby-warning'
gem 'rake'
gem 'rubocop', '~> 1.69.0', require: false
gem 'dyno_metadata'
gem 'localhost'

group :test do
  gem 'climate_control'
  gem 'm'
  gem 'minitest'
  gem 'rack-test'
  gem 'wait_for_it'
  gem 'webmock'
end
