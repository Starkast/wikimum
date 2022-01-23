# frozen_string_literal: true

require_relative 'config/sentry'

require 'rack/ssl-enforcer'

use Raven::Rack

def production?
  ENV.fetch('RACK_ENV') == 'production'
end

def development?
  ENV.fetch('RACK_ENV') == 'development'
end

def test?
  ENV.fetch('RACK_ENV') == 'test'
end

def load_localhost_ssl?
  return true if development?

  ENV.key?("LOAD_LOCALHOST_SSL") # to force load when "simulating" production
end

def redirect_to_https?
  return true if production?

  %w(1 true).include?(ENV["REDIRECT_TO_HTTPS"])
end

require_relative 'config/app'

# SSL/TLS in development on port $PORT-1000 (port $PORT will redirect there)
# https://github.com/socketry/localhost
require 'localhost' if load_localhost_ssl?

if redirect_to_https?
  options = if development?
    # Subtract 100 because of foreman offset bug:
    #   https://github.com/ddollar/foreman/issues/714
    #   https://github.com/ddollar/foreman/issues/418
    { https_port: ENV.fetch('PORT').to_i - 100 - 1000, hsts: false }
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
