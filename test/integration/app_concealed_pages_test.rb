# frozen_string_literal: true

require "cgi"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppConcealedPagesTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def setup
    @page_title = "Concealed ÅÄÖ"
    @user = User.create(email: "test@test", login: "test")
    @page = Page.create(title: @page_title, author: @user, concealed: true)
  end

  def teardown
    @page.destroy
    @user.destroy
  end

  def login_as_starkast
    session = { login: @user.login, user_id: @user.id, starkast: true }
    env "rack.session", session
    header "X-CSRF-Token", Rack::Protection::AuthenticityToken.token(session)
  end

  def test_concealed
    get "/#{@page.slug_for_uri}"
    follow_redirect!
    assert last_response.body.include?("Not authorized")
    assert last_response.ok?
  end

  def test_concealed_logged_in_as_starkast
    login_as_starkast
    get "/#{@page.slug_for_uri}"
    assert last_response.ok?
  end

  def test_concealed_edit_view_logged_in_as_starkast
    login_as_starkast
    get "/#{@page.slug_for_uri}/edit"
    assert last_response.ok?
  end

  def test_toggle_concealed_logged_in_as_starkast
    login_as_starkast
    assert_equal true, @page.concealed

    post "/#{@page.slug_for_uri}/conceal"

    redirect_location = last_response["Location"]
    assert_equal 302, last_response.status
    assert_equal "/#{@page.slug_for_uri}", URI(redirect_location).path
    assert_equal false, @page.reload.concealed
  end

  def test_latest
    get "/latest"
    refute last_response.body.include?(@page_title)
    assert last_response.ok?
  end

  def test_latest_logged_in_as_starkast
    login_as_starkast
    get "/latest"
    assert last_response.body.include?(@page_title)
    assert last_response.ok?
  end

  def test_list
    get "/list"
    refute last_response.body.include?(@page_title)
    assert last_response.ok?
  end

  def test_list_logged_in_as_starkast
    login_as_starkast
    get "/list"
    assert last_response.body.include?(@page_title)
    assert last_response.ok?
  end

  def test_search_does_not_leak_concealed_pages
    visible1 = Page.create(title: "Visible ÅÄÖ one", author: @user)
    visible2 = Page.create(title: "Visible ÅÄÖ two", author: @user)

    get "/search?q=#{CGI.escape('ÅÄÖ')}"

    assert last_response.ok?
    refute last_response.body.include?(@page_title),
      "concealed page should not appear in search results for non-starkast users"
    assert last_response.body.include?(visible1.title)
    assert last_response.body.include?(visible2.title)
  ensure
    visible1&.destroy
    visible2&.destroy
  end

  def test_search_includes_concealed_pages_when_logged_in_as_starkast
    login_as_starkast
    visible = Page.create(title: "Visible ÅÄÖ", author: @user)

    get "/search?q=#{CGI.escape('ÅÄÖ')}"

    assert last_response.ok?
    assert last_response.body.include?(@page_title)
    assert last_response.body.include?(visible.title)
  ensure
    visible&.destroy
  end

  def test_etag_does_not_short_circuit_concealed_redirect_for_anonymous
    # Anonymous visitor sends an If-None-Match that *would* match the etag
    # computed for an anonymous view of this concealed page. The auth-gate
    # (restrict_concealed) must run BEFORE the etag check so the 304
    # path can't bypass authorization. If the order ever swaps, a 304 is
    # returned instead of the 302 redirect.
    # Sinatra's `etag` helper wraps the value in double quotes per HTTP spec,
    # so If-None-Match must match the quoted form to actually short-circuit.
    matching_etag = %("#{[@page.sha1, "c", "p", "u"].join("-")}")
    header "If-None-Match", matching_etag

    get "/#{@page.slug_for_uri}"

    refute_equal 304, last_response.status,
      "etag check must run after restrict_concealed; got 304 — auth gate bypassed"
    assert_equal 302, last_response.status
  end

  def test_etag_encodes_starkast_audience_with_s_suffix
    login_as_starkast
    get "/#{@page.slug_for_uri}"

    assert last_response.ok?
    assert_match(/-a-s\b/, last_response.headers["ETag"].to_s,
      "starkast ETag should end with -a-s, got #{last_response.headers["ETag"].inspect}")
  end
end
