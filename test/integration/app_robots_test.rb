# frozen_string_literal: true

require "cgi"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppRobotsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def setup
    @user = User.create(email: "test@test", login: "test")
  end

  def teardown
    @user.destroy
  end

  def test_robots_txt_disallows_everything_by_default
    get "/robots.txt"

    assert last_response.ok?
    assert_includes last_response.content_type, "text/plain"
    assert_includes last_response.body, "User-Agent: *"
    assert_includes last_response.body, "Disallow: /"
  end

  def test_robots_txt_allows_crawlable_pages
    page = Page.create(title: "Public Doc", author: @user, visibility: "crawlable")

    get "/robots.txt"

    assert_includes last_response.body, "Allow: /#{page.slug_for_uri}"
  ensure
    page&.destroy
  end

  def test_robots_txt_excludes_plain_public_pages
    page = Page.create(title: "Internal Doc", author: @user)

    get "/robots.txt"

    refute_includes last_response.body, "Allow: /#{page.slug_for_uri}"
  ensure
    page&.destroy
  end

  def test_robots_txt_never_lists_concealed_pages
    page = Page.create(title: "Hidden Doc", author: @user, visibility: "concealed")

    get "/robots.txt"

    refute_includes last_response.body, "Allow: /#{page.slug_for_uri}"
  ensure
    page&.destroy
  end

  def test_non_crawlable_page_is_noindex
    page = Page.create(title: "Internal Doc", author: @user)

    get "/#{page.slug_for_uri}"

    assert_includes last_response.body, 'content="noindex"',
      "non-crawlable pages should carry a robots noindex meta tag"
  ensure
    page&.destroy
  end

  def test_crawlable_page_is_indexable
    page = Page.create(title: "Public Doc", author: @user, visibility: "crawlable")

    get "/#{page.slug_for_uri}"

    refute_includes last_response.body, 'content="noindex"',
      "crawlable pages must not carry a noindex meta tag"
  ensure
    page&.destroy
  end
end
