# frozen_string_literal: true

require "raven"
require "logger"

Raven.configure do |config|
  config.logger.level = Logger::DEBUG
  config.processors -= [Raven::Processor::PostData] # send POST data
  config.processors -= [Raven::Processor::Cookies]  # send cookies
end
