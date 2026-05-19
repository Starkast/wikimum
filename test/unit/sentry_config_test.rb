# frozen_string_literal: true

require_relative '../test_helper'

class SentryConfigTest < Minitest::Test
  CONFIG_PATH = File.expand_path("../../../config/sentry.rb", __FILE__)

  # `test/unit/page_test.rb` already loads `config.ru` at file-load time, which
  # runs `Sentry.init` with no DSN and registers an `at_exit { close }`. That
  # close fires before Minitest's run hook, leaving Sentry uninitialised when
  # tests execute. We `load` (not `require`) the file with a DSN set so
  # Sentry.init runs again here and `Sentry.configuration` is populated.
  def setup
    ENV["SENTRY_DSN"] = "https://public@sentry.example.com/1"
    load CONFIG_PATH
  end

  def test_httpx_adapter_registered
    assert Sentry.registered_patches.key?(:httpx),
      "Expected config/sentry.rb to register the httpx Sentry adapter"
  end

  def test_httpx_patch_enabled
    assert_includes Sentry.configuration.enabled_patches, :httpx,
      "Expected config/sentry.rb to enable the :httpx patch"
  end
end
