# frozen_string_literal: true

require "sequel"
require "securerandom"

module TestDatabase
  module_function

  def create(prefix)
    return ENV["TEST_DATABASE_URL"] if ENV["TEST_DATABASE_URL"]

    database_name = "#{prefix}_#{SecureRandom.hex}"

    system("createdb #{database_name}")

    "postgres://localhost/#{database_name}"
  end

  def migrate
    Sequel.connect(ENV.fetch("DATABASE_URL")) do |db|
      Sequel.extension :migration
      Sequel::Migrator.run(db, "migrations")
    end
  end

  def disconnect_and_drop
    database_name = DB.url.split("/").last

    DB.disconnect

    system("dropdb #{database_name}") unless ENV["TEST_DATABASE_URL"]
  end
end

