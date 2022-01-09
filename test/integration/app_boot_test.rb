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

  def setup
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  def teardown
    WebMock.disable_net_connect!
  end

  def test_app_boot
    options = {
      timeout: 5,
      wait_for: /Worker.+booted/,
    }

    WaitForIt.new(command_from_procfile, options) do |spawn|
    end
  end

  def test_app_development_boot
    port = random_free_port.to_s
    options = {
      timeout: 5,
      wait_for: /Worker.+booted/,
    }

    ClimateControl.modify(RACK_ENV: "development", PORT: port) do
      command = command_from_procfile(worker: "development")

      WaitForIt.new(command, options) do |spawn|
        puts spawn.log.read if ENV.key?("DEBUG")
        actual_port = (port.to_i - 100) # because we workaround foreman issue in Procfile

        res = Net::HTTP.get_response(URI("http://localhost:#{actual_port}"))
        assert_equal "301", res.code

        https_res = nil
        https_port = actual_port - 1000
        ssl_opts = {
          use_ssl: true,
          verify_mode: OpenSSL::SSL::VERIFY_NONE,
        }
        Net::HTTP.start("localhost", https_port, ssl_opts) do |http|
          https_res = http.get("/")
        end

        assert_equal "200", https_res.code
        refute https_res.key?("strict-transport-security")
      end
    end
  end

  def test_app_production_boot
    port = random_free_port.to_s
    options = {
      timeout: 5,
      wait_for: /Worker.+booted/,
    }

    ClimateControl.modify(RACK_ENV: "testprod", PORT: port) do
      command = command_from_procfile(worker: "testprod")

      WaitForIt.new(command, options) do |spawn|
        puts spawn.log.read if ENV.key?("DEBUG")
        actual_port = (port.to_i - 100) # because we workaround foreman issue in Procfile

        res = Net::HTTP.get_response(URI("http://localhost:#{actual_port}"))
        assert_equal "301", res.code

        https_res = nil
        https_port = actual_port - 1000
        ssl_opts = {
          use_ssl: true,
          verify_mode: OpenSSL::SSL::VERIFY_NONE,
        }
        Net::HTTP.start("localhost", https_port, ssl_opts) do |http|
          https_res = http.get("/")
        end

        assert_equal "200", https_res.code
        assert_equal ["max-age=31536000"], https_res.get_fields("strict-transport-security")
      end
    end
  end
end
