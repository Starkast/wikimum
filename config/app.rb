# frozen_string_literal: true

require 'sinatra/base'
require 'sequel'

if ENV.fetch('RACK_ENV') == 'development'
  ENV['SESSION_SECRET'] ||= 'secret'

  $stdout.sync = true
  $stderr.sync = true
end

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'postgres://localhost/wikimum'))

if ENV.fetch('RACK_ENV') == 'development'
  require 'logger'
  DB.logger = Logger.new($stdout)

  # Enable filtered warnings
  require_relative 'filtered_warnings'
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'services'
require 'models'
require 'controllers'
