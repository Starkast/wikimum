require 'rack/ssl'
require 'opbeat'

use Opbeat::Rack

Opbeat.configure do |config|
  config.organization_id = ENV['OPBEAT_ORGANIZATION_ID']
  config.app_id          = ENV['OPBEAT_APP_ID']
  config.secret_token    = ENV['OPBEAT_SECRET_TOKEN']
  config.environments    = %(production)
end

require_relative 'config/environment'

unless ENV.fetch('RACK_ENV') == 'development'
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
