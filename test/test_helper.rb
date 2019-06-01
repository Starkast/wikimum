# frozen_string_literal: true

require "minitest/autorun"
require "rack/test"

ENV["DATABASE_URL"] = "postgres://localhost/wikimum_test"
ENV["RACK_ENV"] = "test"
ENV["SESSION_SECRET"] = "test"


# Enable filtered warnings
require_relative '../config/filtered_warnings'

require "sequel"
Sequel.extension :migration
Sequel::Migrator.run(Sequel.connect(ENV.fetch("DATABASE_URL")), "migrations")
