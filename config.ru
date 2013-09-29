require 'bundler'

Bundler.require

if ENV['RACK_ENV'] == 'development'
  require 'dotenv'
  Dotenv.load

  $stdout.sync = true
  $stderr.sync = true
end

require './config/environment'
require './lib/services'
require './lib/models'
require './lib/controllers'

map '/' do
  use Rack::Static, {
    :root => "public",
    :urls => ["/stylesheets", "/images", "/javascripts", "/favicon.ico", "/robots.txt"],
    :cache_control => "public,max-age=#{365 * 24 * 3600}"
  }

  run PageController
end
