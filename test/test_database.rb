# frozen_string_literal: true

require "sequel"
require "securerandom"
require "tmpdir"
require "fileutils"

module TestDatabase
  module_function

  def create(prefix)
    return ENV["TEST_DATABASE_URL"] if database_supplied?

    path = File.join(Dir.tmpdir, "#{prefix}_#{SecureRandom.hex}.sqlite3")
    "sqlite://#{path}"
  end

  def migrate
    Sequel.connect(database_url) do |db|
      Sequel.extension :migration
      Sequel::Migrator.run(db, "migrations")
    end
  end

  def disconnect_and_drop(prefix)
    DB.disconnect if defined? DB

    return if database_supplied?

    path = database_url.sub(%r{\Asqlite://}, "")
    return unless File.basename(path).start_with?(prefix) # safety check

    FileUtils.rm_f(path)
  end

  def database_url
    ENV.fetch("DATABASE_URL")
  end

  def database_supplied?
    ENV.key?("TEST_DATABASE_URL")
  end
end
