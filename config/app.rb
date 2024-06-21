# frozen_string_literal: true

require 'sinatra/base'
require 'sequel'

require_relative '../lib/app'
require_relative 'database'

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
