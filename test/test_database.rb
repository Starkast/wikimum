# frozen_string_literal: true

require "sequel"
require "securerandom"

module TestDatabase
  module_function

  def create(prefix)
    database_name = "#{prefix}_#{SecureRandom.hex}"

    system("createdb #{database_name}")

    "postgres://#{user}@#{server}/#{database_name}"
  end

  def user
    ENV.fetch("TRAVIS", false) ? "postgres" : ""
  end

  def server
    ENV.fetch("PGHOST", "localhost")
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

    system("dropdb #{database_name}")
  end
end

