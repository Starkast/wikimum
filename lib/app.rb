# frozen_string_literal: true

require "logger"
require "rack/utils"

require_relative "services/app_metadata"

class App
  class << self
    def port
      ENV.fetch("PORT", 3000).to_i
    end

    def ssl_port
      port - 1000
    end

    def env
      ENV.fetch("RACK_ENV", "development")
    end

    def production?
      env == "production"
    end

    def development?
      env == "development"
    end

    def test?
      env == "test"
    end

    def null_logger
      Logger.new(File.open(File::NULL, "w"))
    end

    def backup_access?(username, password)
      backup_user = ENV.fetch("BACKUP_USER")
      backup_pass = ENV.fetch("BACKUP_PASSWORD")
      username_ok = Rack::Utils.secure_compare(backup_user, username)
      password_ok = Rack::Utils.secure_compare(backup_pass, password)

      username_ok && password_ok
    end

    def maintenance_mode?
      ENV["MAINTENANCE_MODE"] == "true"
    end

    def test_lowlevel_error_handler?
      ENV.key?("TEST_LOWLEVEL_ERROR_HANDLER")
    end

    def localhost_ssl?
      return true if development?

      # to force use when "simulating" production
      ENV.key?("LOAD_LOCALHOST_SSL")
    end

    def redirect_to_https?
      return true if production?

      %w(1 true).include?(ENV["REDIRECT_TO_HTTPS"])
    end
  end

  if production?
    def self.cache_bust
      AppMetadata.release_version
    end
  else
    def self.cache_bust
      rand(10_000)
    end
  end
end
