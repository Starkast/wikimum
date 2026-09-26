# frozen_string_literal: true

require_relative "../lib/app"

# Workers come from WEB_CONCURRENCY, default 0 (single mode). In cluster mode
# the master replaces crashed or hung workers.
threads 1, App.max_threads

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

silence_fork_callback_warning

# preload_app! may connect in the master, don't share those sockets with workers
before_fork do
  App.db.disconnect
end
