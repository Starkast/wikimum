# frozen_string_literal: true

require_relative 'config/sentry'

require 'rack/ssl'

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

def production_test?
  ENV.fetch('RACK_ENV') == 'testprod'
end

require_relative 'config/app'

# SSL/TLS in development on port $PORT-1000 (port $PORT will redirect there)
# https://github.com/socketry/localhost
require 'localhost' if development? || production_test?

unless test?
  options = if development?
    # Subtract 100 because of foreman offset bug:
    #   https://github.com/ddollar/foreman/issues/714
    #   https://github.com/ddollar/foreman/issues/418
    { host: "localhost:#{ENV.fetch('PORT').to_i - 100 - 1000}", hsts: false }
  else
    {}
  end

  use Rack::SSL, options
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
