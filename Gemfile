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
gem 'rack-ssl'
gem 'html-pipeline'
gem 'github-markup'
gem 'commonmarker'
gem 'rest-client'
gem 'octokit'
gem 'addressable'
gem 'sentry-raven'
gem 'racksh'
gem 'warning'

group :development do
  gem 'foreman'
  gem 'rake'
  gem 'rubocop', '~> 1.7.0', require: false
  gem 'pry'
end

group :test do
  gem 'minitest'
  gem 'rack-test'
  gem 'wait_for_it'
end
