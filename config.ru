require 'bundler'

Bundler.require

require './config/environment'
require './lib/services'
require './lib/models'
require './lib/controllers'

if ENV['RACK_ENV'] == 'development'
  $stdout.sync = true
  $stderr.sync = true
end

map '/' do
  use Rack::Static, {
    :root => "public",
    :urls => ["/stylesheets", "/images", "/javascripts", "/favicon.ico", "/robots.txt"],
    :cache_control => "public,max-age=#{365 * 24 * 3600}"
  }

  run PageController
end
