# frozen_string_literal: true

require 'sinatra/base'
require 'sequel'

require_relative '../lib/app'

if App.development?
  ENV['SESSION_SECRET'] ||= 'secret'

  $stdout.sync = true
  $stderr.sync = true
end

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'postgres://localhost/wikimum'))

# https://github.com/Starkast/wikimum/issues/412
# https://sequel.jeremyevans.net/rdoc-plugins/files/lib/sequel/extensions/connection_validator_rb.html
DB.extension(:connection_validator)
DB.pool.connection_validation_timeout = 60 * 5

if App.development?
  require 'logger'
  DB.logger = Logger.new($stdout)

  # Enable filtered warnings
  require_relative 'filtered_warnings'
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'services'
require 'models'
require 'controllers'
