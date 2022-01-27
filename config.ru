# frozen_string_literal: true

require_relative 'config/sentry'

require 'rack/ssl-enforcer'

use Raven::Rack

require_relative 'config/app'

use BrokenApp if App.test_lowlevel_error_handler?

if App.redirect_to_https?
  options = if App.development?
    { https_port: App.ssl_port, hsts: false }
  else
    { hsts: { subdomains: false } }
  end

  use Rack::SslEnforcer, options
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
