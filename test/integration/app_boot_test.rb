# frozen_string_literal: true

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

  def test_app_boot
    options = {
      timeout: 5,
      wait_for: /Worker.+booted/,
    }

    WaitForIt.new(command_from_procfile, options) do |spawn|
    end
  end
end
