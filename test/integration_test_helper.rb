# frozen_string_literal: true

# With Rack 3, rack-test does not autoload Rack::Builder
# https://github.com/rack/rack-test/commit/29cb95c9588d73e5ee436ead9e6887d5bd341abc
require "rack/builder"
require "rack/test"
require "securerandom"
require_relative "test_database"

ENV["DATABASE_URL"] = TestDatabase.create("wikimum_test")
ENV["RACK_ENV"] = "test"

# Rack::Session::Cookie encrypted when using rack-session 0.3.0 or v2.x used
# https://github.com/rack/rack/commit/c394c4d645cdc574c18f4a8ed3f162e28cb04d6d
# https://github.com/rack/rack/pull/1805
# https://github.com/rack/rack-session
ENV["SESSION_SECRET"] = SecureRandom.hex(32)

TestDatabase.migrate

# Since https://github.com/rack/rack/pull/1663
# Rack::Builder.parse_file returns only the app
DYNAMIC_APP = ->() { Rack::Builder.parse_file("config.ru") }
STATIC_APP  = DYNAMIC_APP.call

Minitest.after_run do
  TestDatabase.disconnect_and_drop("wikimum_test")
end
