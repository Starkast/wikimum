# frozen_string_literal: true

require "sentry-ruby"
require "logger"

require_relative "../lib/app"

Sentry.init do |config|
  config.sdk_logger = App.null_logger if App.test?
  config.sdk_logger.level = Logger::DEBUG

  # https://docs.sentry.io/platforms/ruby/configuration/releases/#release-health
  config.auto_session_tracking = false

  # send POST data send cookies
  # https://docs.sentry.io/platforms/ruby/migration/#removed-processors
  config.send_default_pii = true
end
