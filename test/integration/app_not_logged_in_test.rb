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

  def test_page
    get "/#{CGI.escape(@page.slug)}"
    assert last_response.body.include?(@page_title)
    assert last_response.ok?
  end

  def test_nonexistent_page
    random_slug = SecureRandom.hex
    get "/#{random_slug}"

    redirect_location = last_response["Location"]
    assert_equal 302, last_response.status
    assert_equal "/new/#{random_slug}", URI(redirect_location).path
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
    get "/latest"
    assert last_response.body.include?("<h2>#{Time.now.to_date}</h2>")
    assert last_response.ok?
  end

  def test_list
    get "/list"
    assert last_response.body.include?(">#{@page.title}</a>")
    assert last_response.ok?
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
