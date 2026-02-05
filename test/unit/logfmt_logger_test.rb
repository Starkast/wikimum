# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/services/logfmt_logger'

class LogfmtLoggerTest < Minitest::Test
  def setup
    @output = StringIO.new
    @log = LogfmtLogger.new(@output)
  end

  def test_info_outputs_at_info
    @log.info foo: "bar"

    assert_equal "at=info foo=bar\n", @output.string
  end

  def test_warn_outputs_at_warn
    @log.warn foo: "bar"

    assert_equal "at=warn foo=bar\n", @output.string
  end

  def test_error_outputs_at_error
    @log.error foo: "bar"

    assert_equal "at=error foo=bar\n", @output.string
  end

  def test_multiple_keys
    @log.info class: "MyClass", method: "my_method", count: 42

    assert_equal "at=info class=MyClass method=my_method count=42\n", @output.string
  end

  def test_quotes_values_with_spaces
    @log.info title: "Hello World"

    assert_equal "at=info title=\"Hello World\"\n", @output.string
  end

  def test_quotes_values_with_equals
    @log.info query: "foo=bar"

    assert_equal "at=info query=\"foo=bar\"\n", @output.string
  end

  def test_quotes_empty_values
    @log.info value: ""

    assert_equal "at=info value=\"\"\n", @output.string
  end

  def test_escapes_quotes_in_values
    @log.info message: 'said "hello"'

    assert_equal "at=info message=\"said \\\"hello\\\"\"\n", @output.string
  end

  def test_handles_numeric_values
    @log.info bytes: 1234, ratio: 3.14

    assert_equal "at=info bytes=1234 ratio=3.14\n", @output.string
  end

  def test_handles_symbol_values
    @log.info status: :ok

    assert_equal "at=info status=ok\n", @output.string
  end

  def test_handles_class_names
    @log.info error: StandardError

    assert_equal "at=info error=StandardError\n", @output.string
  end
end
