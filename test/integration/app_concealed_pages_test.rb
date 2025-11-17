# frozen_string_literal: true

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
    env "rack.session", { login: @user.login, user_id: @user.id, starkast: true }
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
end
