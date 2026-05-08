# frozen_string_literal: true

require 'sinatra/base'
require 'sequel'
require 'zeitwerk'

require_relative '../lib/app'

loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path('../lib', __dir__))
# prefer not to have these directories as namespaces
# https://github.com/fxn/zeitwerk#collapsing-directories
loader.collapse(File.expand_path('../lib/services', __dir__))
loader.collapse(File.expand_path('../lib/models', __dir__))
loader.collapse(File.expand_path('../lib/controllers', __dir__))
loader.enable_reloading if App.development?
loader.setup

require_relative 'database'

if App.development?
  require 'logger'
  DB.logger = Logger.new($stdout)

  # Enable filtered warnings
  require_relative 'filtered_warnings'
end

App.db = DB
