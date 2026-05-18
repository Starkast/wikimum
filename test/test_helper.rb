# frozen_string_literal: true

require "climate_control"
require "minitest/autorun"
require "webmock"
require "httpx"
require "httpx/adapters/webmock"
require "webmock/minitest"

# Enable filtered warnings
require_relative '../config/filtered_warnings'
