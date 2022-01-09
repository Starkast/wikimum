# frozen_string_literal: true

require "rack/test"
require_relative "test_database"

ENV["DATABASE_URL"] = TestDatabase.create("wikimum_test")
ENV["RACK_ENV"] = "test"
ENV["SESSION_SECRET"] = "test"

TestDatabase.migrate

Minitest.after_run do
  TestDatabase.disconnect_and_drop("wikimum_test")
end
