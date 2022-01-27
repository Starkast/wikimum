# frozen_string_literal: true

require_relative "../lib/app"

workers Integer(ENV['PUMA_WORKERS'] || 3)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 16)

preload_app!

rackup      DefaultRackup
port        App.port
environment App.env

if App.localhost_ssl?
  require "localhost" # https://github.com/socketry/localhost
  # SSL/TLS in development on port $PORT-1000 (port $PORT will redirect there)
  ssl_bind "0.0.0.0", App.ssl_port
end

lowlevel_error_handler do |ex, env|
  Raven.capture_exception(
    ex,
    :message => ex.message,
    :extra => { :puma => env },
    :transaction => "Puma"
  )
  [500, {}, ["An error has occurred, and engineers have been informed.\n"]]
end

on_worker_boot do
  DB.disconnect
end
