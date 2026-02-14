# frozen_string_literal: true

require "cgi"
require "json"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppLinkTitlesTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def ensure_logged_in_user(user)
    env "rack.session", { login: user.login, user_id: user.id }
  end

  def setup
    @user = User.create(email: "test@test", login: "test")
    @page = Page.create(title: "Test Page", author: @user)
    @original_fetcher = App.link_title_fetcher
  end

  def teardown
    App.link_title_fetcher = @original_fetcher
    @page.revisions.each(&:destroy)
    @page.destroy
    @user.destroy
  end

  def test_link_title_requires_login
    env "rack.session", {}

    post "/link-title", url: "https://example.com"

    assert_equal 302, last_response.status
  end

  def test_link_title_missing_url
    ensure_logged_in_user(@user)

    post "/link-title"

    assert_equal 400, last_response.status
    assert_equal "Missing URL", last_response.body
  end

  def test_link_title_returns_json
    ensure_logged_in_user(@user)
    App.link_title_fetcher = MockFetcher.new(title: "Example Page")

    post "/link-title", url: "https://example.com"

    assert_equal 200, last_response.status
    assert last_response.content_type.start_with?("application/json")
    response = JSON.parse(last_response.body)
    assert_equal "https://example.com", response["url"]
    assert_equal "Example Page", response["title"]
  end

  def test_link_title_returns_error
    ensure_logged_in_user(@user)
    App.link_title_fetcher = MockFetcher.new(error: "Connection refused")

    post "/link-title", url: "https://example.com"

    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    assert_equal "Connection refused", response["error"]
  end

  def test_link_title_blocks_private_ip
    ensure_logged_in_user(@user)

    post "/link-title", url: "http://192.168.1.1"

    assert_equal 400, last_response.status
    assert_equal "Invalid URL", last_response.body
  end

  def test_link_title_blocks_localhost
    ensure_logged_in_user(@user)

    post "/link-title", url: "http://localhost:8080"

    assert_equal 400, last_response.status
    assert_equal "Invalid URL", last_response.body
  end
end

class MockFetcher
  def initialize(title: nil, error: nil)
    @title = title
    @error = error
  end

  def fetch_title(url)
    { url: url, title: @title, error: @error }
  end
end
