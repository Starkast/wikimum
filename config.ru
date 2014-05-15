require 'bundler/setup'

if ENV.fetch('RACK_ENV') == 'development'
  require 'dotenv'
  Dotenv.load

  $stdout.sync = true
  $stderr.sync = true
end

require 'sinatra/base'

$:.unshift File.join(File.dirname(__FILE__), 'lib')

require './config/environment'
require 'services'
require 'models'
require 'controllers'

map '/' do
  use Rack::Static, {
    root: "public",
    urls: ["/stylesheets", "/images", "/javascripts", "/favicon.ico", "/robots.txt"],
    cache_control: "public,max-age=#{365 * 24 * 3600}"
  }

  run PageController
end
