# frozen_string_literal: true

source 'https://rubygems.org/'
ruby file: '.ruby-version'

gem 'sequel', "5.108.0"
gem 'pg'
gem 'sequel_pg', require: 'sequel'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'rack-flash3', require: 'rack-flash'
gem 'haml'
gem 'puma'
gem 'spinels-rack-ssl-enforcer'
gem 'html-pipeline'
gem 'commonmarker'
gem 'httpx'
gem 'addressable'
gem 'sentry-ruby'
gem 'logger'
gem 'rake'
gem 'zeitwerk'
gem 'dyno_metadata'

# Not installed in production, see BUNDLE_WITHOUT in Starkast/ansible
group :development do
  gem 'localhost'
  gem 'racksh'
  gem 'rubocop', '~> 1.89.0', require: false
end

group :development, :test do
  gem 'warning'
end

group :test do
  gem 'climate_control'
  gem 'm'
  gem 'minitest'
  gem 'rack-test'
  gem 'wait_for_it'
  gem 'webmock'
end
