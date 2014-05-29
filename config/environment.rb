require 'sinatra/base'
require 'sequel'

if ENV.fetch('RACK_ENV') == 'development'
  require 'dotenv'
  Dotenv.load

  ENV['SESSION_SECRET'] ||= 'secret'

  $stdout.sync = true
  $stderr.sync = true
end

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))

if ENV.fetch('RACK_ENV') == 'development'
  require 'logger'
  DB.logger = Logger.new($stdout)
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'services'
require 'models'
require 'controllers'
