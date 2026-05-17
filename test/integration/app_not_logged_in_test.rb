# frozen_string_literal: true

require "cgi"
require "securerandom"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppNotLoggedInTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def setup
    @page_title = "Test åäö"
    @user = User.create(email: "test@test", login: "test")
    @page = Page.create(title: @page_title, author: @user)
  end

  def teardown
    @page.destroy
    @user.destroy
  end

  def test_root
    get "/"
    assert last_response.ok?
  end

  def test_session_cookie_is_named_wikimum_session
    # Cookie name must be `wikimum_session` (no dot) so nginx in front can
    # reference it as `$cookie_wikimum_session` for cache-bypass rules.
    get "/"
    cookie = last_response.headers["Set-Cookie"].to_s
    assert_match(/^wikimum_session=/, cookie,
      "expected wikimum_session= prefix, got: #{cookie.inspect}")
  end

  def test_root_sets_etag_header_for_anonymous_visitors
    get "/"
    assert last_response.ok?
    assert_match(/-p-u\b/, last_response.headers["ETag"].to_s,
      "anonymous ETag should end with -p-u, got #{last_response.headers["ETag"].inspect}")
  end

  def test_root_returns_304_when_etag_matches
    get "/"
    etag = last_response.headers["ETag"]
    refute_nil etag

    header "If-None-Match", etag
    get "/"

    assert_equal 304, last_response.status
    assert_empty last_response.body
  end

  def test_root_uses_one_bounded_query_and_renders_author
    # Create extra pages so the route can't accidentally fetch the whole
    # table — `Page.eager_graph(:author).all.first` without LIMIT would
    # materialise every page row joined with users in memory.
    extras = 3.times.map { |i| Page.create(title: "Extra #{i}", author: @user) }

    queries = capture_db_queries { get "/" }

    assert last_response.ok?
    assert_includes last_response.body, @page.title
    assert_match(/av\s+#{Regexp.escape(@user.login)}/, last_response.body,
      "expected author login rendered by _actions partial")
    assert_equal 1, queries.size,
      "GET / should use one DB query, got #{queries.size}: #{queries.inspect}"
    assert_match(/LIMIT 1\b/i, queries.first,
      "GET / must bound the page lookup with LIMIT 1, got: #{queries.first.inspect}")
  ensure
    extras&.each(&:destroy)
  end

  def test_page
    get "/#{CGI.escape(@page.slug)}"
    assert last_response.body.include?(@page_title)
    assert last_response.ok?
  end

  def test_page_sets_etag_header_for_anonymous_visitors
    get "/#{CGI.escape(@page.slug)}"
    assert last_response.ok?
    # Encoded suffix: -<a|p>-<s|u> = anonymous, not starkast
    assert_match(/-p-u\b/, last_response.headers["ETag"].to_s,
      "anonymous ETag should end with -p-u, got #{last_response.headers["ETag"].inspect}")
  end

  def test_page_returns_304_when_etag_matches
    get "/#{CGI.escape(@page.slug)}"
    etag = last_response.headers["ETag"]
    refute_nil etag

    header "If-None-Match", etag
    get "/#{CGI.escape(@page.slug)}"

    assert_equal 304, last_response.status
    assert_empty last_response.body
  end

  def test_page_show_uses_one_query_and_renders_author
    queries = []
    counting = Logger.new(File::NULL).tap do |l|
      l.define_singleton_method(:add) do |_severity, message = nil, progname = nil|
        sql = message || progname
        queries << sql if sql.is_a?(String)
        true
      end
    end
    DB.loggers << counting
    begin
      get "/#{CGI.escape(@page.slug)}"
    ensure
      DB.loggers.delete(counting)
    end

    assert last_response.ok?
    assert_includes last_response.body, @page_title
    assert_match(/av\s+#{Regexp.escape(@user.login)}/, last_response.body, "expected author login rendered by _actions partial")
    assert_equal 1, queries.size, "GET /:slug should use one DB query, got #{queries.size}: #{queries.inspect}"
    assert_match(/LIMIT 1\b/i, queries.first,
      "GET /:slug must bound the page lookup with LIMIT 1, got: #{queries.first.inspect}")
  end

  def test_nonexistent_page
    random_slug = SecureRandom.hex
    get "/#{random_slug}"

    redirect_location = last_response["Location"]
    assert_equal 302, last_response.status
    assert_equal "/new/#{random_slug}", URI(redirect_location).path
  end

  def test_new
    get "/new"

    assert_equal 302, last_response.status
    assert_equal "/", URI(last_response["Location"]).path
    follow_redirect!
    assert last_response.body.include?("You need to be logged in to create a new page!")
  end

  def test_new_slug
    random_slug = SecureRandom.hex
    get "/new/#{random_slug}"

    assert_equal 302, last_response.status
    assert_equal "/", URI(last_response["Location"]).path
    follow_redirect!
    assert last_response.body.include?("You need to be logged in to create a new page!")
  end

  def test_page_edit_view
    slug = CGI.escape(@page.slug)

    get "/#{slug}/edit"

    redirect_location = last_response["Location"]
    assert_equal 302, last_response.status
    assert_equal "/#{slug}", URI(redirect_location).path
    follow_redirect!
    assert last_response.body.include?("Not authorized to edit!")
  end

  def test_nonexistent_page_edit_view
    random_slug = SecureRandom.hex
    get "/#{random_slug}/edit"

    redirect_location = last_response["Location"]
    assert_equal 302, last_response.status
    assert_equal "/", URI(redirect_location).path
  end

  def test_latest
    @page.this.update(comment: "Important note", revision: 7)
    get "/latest"
    assert last_response.body.include?("<h2>#{Time.now.to_date}</h2>")
    assert last_response.body.include?("av #{@user.login}")
    assert last_response.body.include?("(7)")
    assert last_response.body.include?("Important note")
    assert last_response.ok?
  end

  def test_list
    get "/list"
    assert last_response.body.include?(">#{@page.title}</a>")
    assert last_response.ok?
  end

  def test_search_renders_multiple_hits_with_a_single_query
    other = Page.create(
      title: "Other Test Page",
      description: "Sökbeskrivning för test",
      author: @user,
    )
    queries = capture_db_queries { get "/search?q=test" }

    assert last_response.ok?
    assert last_response.body.include?(">#{@page.title}</a>"), "expected setup page title in body"
    assert last_response.body.include?(">#{other.title}</a>"), "expected second page title in body"
    assert last_response.body.include?("Sökbeskrivning för test"), "expected description in body"
    assert_equal 1, queries.size, "expected /search to use one DB query, got #{queries.size}: #{queries.inspect}"
  ensure
    other&.destroy
  end

  def capture_db_queries
    logger = Logger.new(File::NULL)
    captured = []
    logger.define_singleton_method(:add) do |_severity, message = nil, progname = nil|
      sql = message || progname
      captured << sql if sql.is_a?(String)
      true
    end
    DB.loggers << logger
    yield
    captured
  ensure
    DB.loggers.delete(logger) if logger
  end

  def test_user
    get "/user"
    follow_redirect!
    assert_equal "http://example.org/", last_request.url
    assert last_response.ok?
  end

  def test_user_logged_in
    env "rack.session", { login: @user.login, user_id: @user.id }
    get "/user"
    assert last_response.ok?
  end

  def test_authorize
    client_id = "fake_client_id"
    referer   = "http://fake/referer"

    ClimateControl.modify(GITHUB_BASIC_CLIENT_ID: client_id) do
      header "Referer", referer
      get "/authorize"
    end

    redirect_location = last_response['Location']

    assert_equal 302, last_response.status
    assert redirect_location.include?(client_id)
    assert redirect_location.include?(URI(referer).path)
  end

  def test_authorize_without_referer
    get "/authorize"

    assert_equal 400, last_response.status
  end

  def test_authorize_callback
    access_token = "fake_access_token"
    user = "fake_user"
    code = "fake_code"
    client_id = "fake_github_client_id"
    client_secret = "fake_github_secret"

    github_api_credentials = {
      GITHUB_BASIC_CLIENT_ID: client_id,
      GITHUB_BASIC_SECRET_ID: client_secret,
    }

    github_api_headers = {
      "Authorization" => "token #{access_token}",
      "Content-Type" =>"application/json",
    }

    ClimateControl.modify(github_api_credentials) do
      stub_request(:post, Authorize::GITHUB_OAUTH_TOKEN_URL)
        .with(body: { client_id: client_id, client_secret: client_secret, code: code })
        .to_return(body: { access_token: access_token }.to_json)

      stub_request(:get, "https://api.github.com/user")
        .with(headers: github_api_headers)
        .to_return_json(body: { id: 123, login: user })

      stub_request(:get, "https://api.github.com/orgs/starkast/members/#{user}")
        .with(headers: github_api_headers)
        .to_return_json(body: {})

      get "/authorize/callback?code=#{code}"

      assert_equal 302, last_response.status
      assert_equal "http://#{current_session.default_host}/", last_response["Location"]
    end
  end

  def test_authorize_callback_no_code
    get "/authorize/callback"

    assert_equal 404, last_response.status
    assert_equal "No code", last_response.body
  end

  def test_footer
    get "/"

    footer_html = <<~HTML
      <div id='footer'>
      <hr>
      <ul>
      <li>
      <a href='/cookies'>Om cookies</a>
      </li>
      <li>
      v42
      (<a href='https://github.com/Starkast/wikimum/commit/#{AppMetadata.commit}'>#{AppMetadata.short_commit}</a>)
      </li>
      <li>
      <img alt='Starkast' src='/favicon.ico'>
      </li>
      </ul>

      </div>
    HTML

    assert last_response.body.include?(footer_html)
  end
end
