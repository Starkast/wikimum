# frozen_string_literal: true

require "cgi"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  OUTER_APP = Rack::Builder.parse_file("config.ru").first

  def app
    OUTER_APP
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

  def test_page_edit_view
    get "/#{CGI.escape(@page.slug)}/edit"
    assert last_response.body.include?(@page_title)
    assert last_response.ok?
  end

  def test_latest
    get "/latest"
    assert last_response.body.include?("<h2>#{Time.now.to_date}</h2>")
    assert last_response.ok?
  end

  def test_list
    get "/list"
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
end
