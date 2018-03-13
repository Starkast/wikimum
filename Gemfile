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
gem 'newrelic_rpm', require: false
gem 'octokit'
gem 'addressable'
gem 'sentry-raven'
gem 'racksh'

group :development do
  gem 'foreman'
  gem 'rake'
  gem 'pry'
  gem 'tool', git: 'https://github.com/rkh/tool.git'
end

group :test do
  gem 'minitest'
  gem 'rack-test'
end
