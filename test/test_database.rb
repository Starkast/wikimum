# frozen_string_literal: true

require "sequel"
require "securerandom"

module TestDatabase
  module_function

  def create(prefix)
    return ENV["TEST_DATABASE_URL"] if database_supplied?

    database_name = "#{prefix}_#{SecureRandom.hex}"

    system("createdb #{database_name}")

    "postgres://localhost/#{database_name}"
  end

  def migrate
    Sequel.connect(database_url) do |db|
      Sequel.extension :migration
      Sequel::Migrator.run(db, "migrations")
    end
  end

  def disconnect_and_drop(prefix)
    DB.disconnect if defined? DB

    database_name = database_url.split("/").last
    return unless database_name.start_with?(prefix) # safety check
    return if database_supplied?

    system("dropdb #{database_name}")
  end

  def database_url
    ENV.fetch("DATABASE_URL")
  end

  def database_supplied?
    ENV.key?("TEST_DATABASE_URL")
  end
end
