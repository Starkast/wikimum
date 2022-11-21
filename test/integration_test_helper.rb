# frozen_string_literal: true

require "rack/test"
require_relative "test_database"

ENV["DATABASE_URL"] = TestDatabase.create("wikimum_test")
ENV["RACK_ENV"] = "test"
ENV["SESSION_SECRET"] = "test"

TestDatabase.migrate

DYNAMIC_APP = ->() { Rack::Builder.parse_file("config.ru").first }
STATIC_APP  = DYNAMIC_APP.call

Minitest.after_run do
  TestDatabase.disconnect_and_drop("wikimum_test")
end
