# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/services/url_validator'
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

  def test_fetch_title_from_404_page
    http = MockHttp.new(body: "<html><head><title>Page Not Found</title></head></html>", status: 404)
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_equal "Page Not Found", result[:title]
  end

  def test_fetch_title_404_no_title
    http = MockHttp.new(body: "<html><body>Not found</body></html>", status: 404)
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_nil result[:title]
    assert_equal "No title found", result[:error]
  end

  def test_fetch_title_connection_error
    http = MockHttp.new(error: StandardError.new("connection refused"))
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_nil result[:title]
    assert_equal "connection refused", result[:error]
  end

  def test_follows_redirect_to_safe_url
    http = MockHttpWithRedirects.new([
      { status: 302, headers: { "location" => "https://example.org/page" } },
      { status: 200, body: "<title>Redirected Page</title>" }
    ])
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_equal "Redirected Page", result[:title]
  end

  def test_blocks_redirect_to_private_ip
    http = MockHttpWithRedirects.new([
      { status: 302, headers: { "location" => "http://192.168.1.1/admin" } }
    ])
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "https://example.com", result[:url]
    assert_equal "Redirect to blocked URL", result[:error]
  end

  def test_blocks_redirect_to_localhost
    http = MockHttpWithRedirects.new([
      { status: 302, headers: { "location" => "http://localhost:8080" } }
    ])
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "Redirect to blocked URL", result[:error]
  end

  def test_limits_max_redirects
    http = MockHttpWithRedirects.new([
      { status: 302, headers: { "location" => "https://example.com/1" } },
      { status: 302, headers: { "location" => "https://example.com/2" } },
      { status: 302, headers: { "location" => "https://example.com/3" } },
      { status: 302, headers: { "location" => "https://example.com/4" } }
    ])
    fetcher = LinkTitleFetcher.new(http: http, log: MockLog.new)

    result = fetcher.fetch_title("https://example.com")

    assert_equal "Too many redirects", result[:error]
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
  attr_reader :status, :headers

  def initialize(body, status, headers = {})
    @body = body
    @status = status
    @headers = headers
  end

  def each
    yield @body
  end
end

class MockHttpWithRedirects
  def initialize(responses)
    @responses = responses
    @call_index = 0
  end

  def get(_url, stream: false)
    response = @responses[@call_index]
    @call_index += 1
    MockResponse.new(response[:body] || "", response[:status], response[:headers] || {})
  end
end
