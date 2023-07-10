# frozen_string_literal: true

require_relative 'config/sentry'

use Sentry::Rack::CaptureExceptions

require 'rack/ssl-enforcer'

# Connects to the database
require_relative 'config/app'

if App.test_lowlevel_error_handler?
  require_relative "lib/broken_app"

  use BrokenApp
end

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

map "/.backup" do
  use Rack::Auth::Basic do |username, password|
    App.backup_access?(username, password)
  end

  run BackupController
end

if App.maintenance_mode?
  require_relative "lib/maintenance_mode_app"

  use MaintenanceModeApp
end

map "/authorize" do
  run AuthorizeController
end

map "/user" do
  run UserController
end

run PageController
