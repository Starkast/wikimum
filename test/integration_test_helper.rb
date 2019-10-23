# frozen_string_literal: true

require "rack/test"

ENV["DATABASE_URL"] = "postgres://localhost/wikimum_test"
ENV["RACK_ENV"] = "test"
ENV["SESSION_SECRET"] = "test"

require "sequel"
Sequel.extension :migration
Sequel::Migrator.run(Sequel.connect(ENV.fetch("DATABASE_URL")), "migrations")
