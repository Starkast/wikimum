# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/services/link_title_fetcher'

class LinkTitleFetcherTest < Minitest::Test
  def test_fetch_title_success
    http = MockHttp.new(body: "<html><head><title>Example Domain</title></head></html>", status: 200)
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_equal "Example Domain", result[:title]
    assert_nil result[:error]
  end

  def test_fetch_title_with_html_entities
    http = MockHttp.new(body: "<html><head><title>Tom &amp; Jerry</title></head></html>", status: 200)
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "Tom & Jerry", result[:title]
  end

  def test_fetch_title_no_title
    http = MockHttp.new(body: "<html><body>No title here</body></html>", status: 200)
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_nil result[:title]
    assert_equal "No title found", result[:error]
  end

  def test_fetch_title_http_error
    http = MockHttp.new(body: "", status: 404)
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_nil result[:title]
    assert_equal "HTTP 404", result[:error]
  end

  def test_fetch_title_connection_error
    http = MockHttp.new(error: StandardError.new("connection refused"))
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_nil result[:title]
    assert_equal "connection refused", result[:error]
  end
end

class MockLog
  def info(**kwargs); end
  def warn(**kwargs); end
  def error(**kwargs); end
end

class MockHttp
  def initialize(body: "", status: 200, error: nil)
    @body = body
    @status = status
    @error = error
  end

  def get(_url, stream: false)
    raise @error if @error

    MockResponse.new(@body, @status)
  end
end

class MockResponse
  attr_reader :status

  def initialize(body, status)
    @body = body
    @status = status
  end

  def each
    yield @body
  end
end
