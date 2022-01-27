# frozen_string_literal: true

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
end
