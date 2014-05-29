require 'sinatra/base'
require 'sequel'

if ENV.fetch('RACK_ENV') == 'development'
  require 'dotenv'
  Dotenv.load

  $stdout.sync = true
  $stderr.sync = true
end

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'services'
require 'models'
require 'controllers'
