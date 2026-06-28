# frozen_string_literal: true

require "cgi"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppCsrfTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def setup
    @user = User.create(email: "test@test", login: "test")
    @page = Page.create(title: "CSRF Page", author: @user)
    @session = { login: @user.login, user_id: @user.id }
  end

  def teardown
    @page.revisions.each(&:destroy)
    @page.destroy
    @user.destroy
  end

  def login
    env "rack.session", @session
  end

  # Seeds the same `:csrf` secret into @session so the injected session validates it.
  def csrf_token
    Rack::Protection::AuthenticityToken.token(@session)
  end

  def test_state_changing_post_without_token_is_forbidden
    login

    post "/#{CGI.escape(@page.slug)}", title: @page.title, content: "no token"

    assert_equal 403, last_response.status
  end

  def test_state_changing_post_with_token_param_succeeds
    login

    post "/#{CGI.escape(@page.slug)}", title: @page.title,
                                       content: "with token",
                                       authenticity_token: csrf_token

    assert_equal 302, last_response.status
    assert_equal "with token", @page.reload.content
  end

  def test_state_changing_post_with_token_header_succeeds
    token = csrf_token
    login
    header "X-CSRF-Token", token

    post "/#{CGI.escape(@page.slug)}", title: @page.title, content: "header token"

    assert_equal 302, last_response.status
  ensure
    header "X-CSRF-Token", nil
  end

  def test_rendered_form_token_round_trips
    env "rack.session", { login: @user.login, user_id: @user.id }

    get "/#{CGI.escape(@page.slug)}/edit"
    assert_equal 200, last_response.status
    token = last_response.body[/authenticity_token['"][^>]*?value=['"]([^'"]+)['"]/, 1]
    refute_nil token, "edit form should render a CSRF token"

    post "/#{CGI.escape(@page.slug)}", title: @page.title,
                                       content: "round trip",
                                       authenticity_token: token

    assert_equal 302, last_response.status
    assert_equal "round trip", @page.reload.content
  end

  def test_logged_out_post_still_redirects_without_csrf_check
    env "rack.session", {}

    post "/#{CGI.escape(@page.slug)}", title: @page.title

    assert_equal 302, last_response.status
  end
end
