# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/services/link_title_fetcher'

class LinkTitleFetcherTest < Minitest::Test
  def setup
    @fetcher = LinkTitleFetcher.new
  end

  def test_extract_bare_urls_simple
    content = "Check out https://example.com for more info"
    urls = @fetcher.extract_bare_urls(content)

    assert_equal ["https://example.com"], urls
  end

  def test_extract_bare_urls_multiple
    content = "See https://example.com and http://test.org"
    urls = @fetcher.extract_bare_urls(content)

    assert_equal ["https://example.com", "http://test.org"], urls
  end

  def test_extract_bare_urls_ignores_markdown_links
    content = "Check [Example](https://example.com) for info"
    urls = @fetcher.extract_bare_urls(content)

    assert_empty urls
  end

  def test_extract_bare_urls_mixed_bare_and_linked
    content = "Visit https://bare.com and [Linked](https://linked.com)"
    urls = @fetcher.extract_bare_urls(content)

    assert_equal ["https://bare.com"], urls
  end

  def test_extract_bare_urls_deduplicates
    content = "https://example.com and again https://example.com"
    urls = @fetcher.extract_bare_urls(content)

    assert_equal ["https://example.com"], urls
  end

  def test_extract_bare_urls_with_path
    content = "See https://example.com/path/to/page?query=1"
    urls = @fetcher.extract_bare_urls(content)

    assert_equal ["https://example.com/path/to/page?query=1"], urls
  end

  def test_fetch_title_success
    http = MockHttp.new(body: "<html><head><title>Example Domain</title></head></html>", status: 200)
    fetcher = LinkTitleFetcher.new(http: http)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_equal "Example Domain", result[:title]
    assert_nil result[:error]
  end

  def test_fetch_title_with_html_entities
    http = MockHttp.new(body: "<html><head><title>Tom &amp; Jerry</title></head></html>", status: 200)
    fetcher = LinkTitleFetcher.new(http: http)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "Tom & Jerry", result[:title]
  end

  def test_fetch_title_no_title
    http = MockHttp.new(body: "<html><body>No title here</body></html>", status: 200)
    fetcher = LinkTitleFetcher.new(http: http)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_nil result[:title]
    assert_equal "No title found", result[:error]
  end

  def test_fetch_title_http_error
    http = MockHttp.new(body: "", status: 404)
    fetcher = LinkTitleFetcher.new(http: http)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_nil result[:title]
    assert_equal "HTTP 404", result[:error]
  end

  def test_fetch_title_connection_error
    http = MockHttp.new(error: StandardError.new("connection refused"))
    fetcher = LinkTitleFetcher.new(http: http)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_nil result[:title]
    assert_equal "connection refused", result[:error]
  end

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
