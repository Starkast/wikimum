# frozen_string_literal: true

require "net/http"
require "wait_for_it"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppBootTest < Minitest::Test
  def command_from_procfile(worker: "web", procfile: "Procfile")
    # https://github.com/ddollar/foreman/blob/v0.86.0/lib/foreman/procfile.rb#L87
    regexp = /^([A-Za-z0-9_-]+):\s*(?<command>.+)$/.freeze

    lines = File.readlines(procfile)
    worker_line = lines.find { |line| line.start_with?("#{worker}:") }

    worker_line.match(regexp)[:command]
  end

  def random_free_port(host: "127.0.0.1")
    server = TCPServer.new(host, 0)
    port   = server.addr[1]

    port
  ensure
    server&.close
  end

  def get_http_response(host: "localhost", port:)
    Net::HTTP.get_response(URI("http://#{host}:#{port}"))
  end

  def get_https_response(host: "localhost", port:)
    response = nil
    ssl_opts = {
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    }

    Net::HTTP.start(host, port, ssl_opts) do |https|
      response = https.get("/")
    end

    response
  end

  def setup
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  def teardown
    WebMock.disable_net_connect!
  end

  def test_app_lowlevel_error_handler
    port = random_free_port
    options = {
      timeout: 5,
      wait_for: /Worker.+booted/,
      env: {
        PORT: port,
        RACK_ENV: "development",
        TEST_LOWLEVEL_ERROR_HANDLER: true, # adds broken middleware
      },
    }

    WaitForIt.new(command_from_procfile, options) do |spawn|
      puts spawn.log.read if ENV.key?("DEBUG")

      get_http_response(port: port)

      assert spawn.wait("DEBUG -- sentry: ** [Sentry] Initializing the background worker")
      assert spawn.wait("puma lowlevel_error_handler ran")
    end
  end

  def test_app_development_boot
    port = random_free_port
    options = {
      timeout: 5,
      wait_for: /Worker.+booted/,
      env: {
        PORT: port,
        RACK_ENV: "development",
        REDIRECT_TO_HTTPS: true,
      },
    }

    WaitForIt.new(command_from_procfile, options) do |spawn|
      puts spawn.log.read if ENV.key?("DEBUG")

      http_res   = get_http_response(port: port)
      https_port = port - 1000
      https_res  = get_https_response(port: https_port)

      # Test HTTP respone
      assert_equal ["https://localhost:#{https_port}/"], http_res.get_fields("location")
      assert_equal "301", http_res.code

      # Test HTTPS respone
      assert_equal "200", https_res.code
      refute https_res.key?("strict-transport-security")
    end
  end

  def test_app_production_boot
    port = random_free_port
    options = {
      timeout: 5,
      wait_for: /Worker.+booted/,
      env: {
        PORT: port,
        RACK_ENV: "production",
        LOAD_LOCALHOST_SSL: true, # Tell Puma to bind TLS/SSL port, to simulate production
      },
    }

    # Good to know:
    # command can not be prefixed with ENV variables due to use of "exec" in wait_for_it
    # https://github.com/zombocom/wait_for_it/blob/v0.2.1/lib/wait_for_it.rb#L179-L180
    WaitForIt.new(command_from_procfile, options) do |spawn|
      puts spawn.log.read if ENV.key?("DEBUG")

      http_res   = get_http_response(port: port)
      https_port = port - 1000
      https_res  = get_https_response(port: https_port)

      # Test HTTP respone, should redirect without any port in production
      assert_equal "301", http_res.code
      assert_equal ["https://localhost/"], http_res.get_fields("location")

      # Test HTTPS respone
      assert_equal "200", https_res.code
      assert_equal ["max-age=31536000"], https_res.get_fields("strict-transport-security")
    end
  end
end
