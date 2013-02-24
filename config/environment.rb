require 'sequel'

ENV['RACK_ENV'] ||= 'development'

DB = Sequel.connect(ENV['DATABASE_URL'])
