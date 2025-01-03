# frozen_string_literal: true

require_relative "../lib/app"

workers 0
threads 1, 16

preload_app!

port        App.port
environment App.env

debug        if App.puma_debug_logging?
log_requests if App.puma_request_logging?

if App.localhost_ssl?
  require "localhost" # https://github.com/socketry/localhost
  # SSL/TLS in development on port $PORT-1000 (port $PORT will redirect there)
  ssl_bind "0.0.0.0", App.ssl_port
end

lowlevel_error_handler do |ex, env|
  if App.test_lowlevel_error_handler?
    puts "puma lowlevel_error_handler ran with exception=#{ex.inspect}"
  end

  [500, {}, ["An error has occurred, and engineers have been informed.\n"]]
end

on_worker_boot do
  DB.disconnect
end
