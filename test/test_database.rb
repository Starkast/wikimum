# frozen_string_literal: true

require "sequel"
require "securerandom"
require "tmpdir"
require "fileutils"

module TestDatabase
  module_function

  def setup_env(prefix)
    ENV["DATABASE_DIR"]  = Dir.tmpdir
    ENV["DATABASE_NAME"] = "#{prefix}_#{SecureRandom.hex}"
  end

  def migrate
    Sequel.connect(database_url) do |db|
      Sequel.extension :migration
      Sequel::Migrator.run(db, "migrations")
    end
  end

  def disconnect_and_drop(prefix)
    DB.disconnect if defined? DB

    return unless ENV["DATABASE_NAME"].to_s.start_with?(prefix) # safety check

    FileUtils.rm_f(database_path)
  end

  def database_path
    File.join(ENV.fetch("DATABASE_DIR"), "#{ENV.fetch('DATABASE_NAME')}.db")
  end

  def database_url
    "sqlite://#{database_path}"
  end
end
