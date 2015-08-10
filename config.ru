require 'rack/ssl'
require 'opbeat'

use Opbeat::Rack

def development?
  ENV.fetch('RACK_ENV') == 'development'
end

Opbeat.configure do |config|
  config.organization_id = ENV.fetch('OPBEAT_ORGANIZATION_ID') { "fake" if development? }
  config.app_id          = ENV.fetch('OPBEAT_APP_ID')          { "fake" if development? }
  config.secret_token    = ENV.fetch('OPBEAT_SECRET_TOKEN')    { "fake" if development? }
  config.environments    = %(production)
  config.excluded_exceptions = ['Sinatra::NotFound']
end

require_relative 'config/environment'

unless development?
  use Rack::SSL
end

use Rack::Session::Cookie,
  secret: ENV.fetch('SESSION_SECRET'),
  expire_after: 60 * 60 * 24 * 365

use Rack::Static, {
  root: "public",
  urls: ["/stylesheets", "/images", "/javascripts", "/favicon.ico", "/robots.txt"],
  cache_control: "public,max-age=#{365 * 24 * 3600}"
}

map '/' do
  run PageController
end

map '/authorize' do
  run AuthorizeController
end

map '/user' do
  run UserController
end
