# frozen_string_literal: true

require 'sinatra/base'
require 'sequel'

require_relative '../lib/app'

# https://starkast.wiki/ruby_homebrew_postgres
# https://github.com/ged/ruby-pg/issues/311#issuecomment-1609970533
ENV["PGGSSENCMODE"] = "disable" if App.macos?

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

App.db = DB

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'services'
require 'models'
require 'controllers'
