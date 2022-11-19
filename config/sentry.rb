# frozen_string_literal: true

require "raven"
require "logger"

require_relative "../lib/app"

Raven.configure do |config|
  config.logger = App.null_logger if App.test?
  config.logger.level = Logger::DEBUG
  config.processors -= [Raven::Processor::PostData] # send POST data
  config.processors -= [Raven::Processor::Cookies]  # send cookies
end
