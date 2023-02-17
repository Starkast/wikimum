# frozen_string_literal: true

require "cgi"
require "securerandom"

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppPageEditingTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def ensure_logged_in_user(user)
    env "rack.session", { login: user.login, user_id: user.id }
  end

  def setup
    @page_title = "Test Page"
    @user = User.create(email: "test@test", login: "test")
    @page = Page.create(title: @page_title, author: @user)

    ensure_logged_in_user(@user)
  end

  def teardown
    @page.revisions.each(&:destroy)
    @page.destroy
    @user.destroy
  end

  def test_page_edit_no_payload
    post "/#{CGI.escape(@page.slug)}"

    assert_equal 400, last_response.status
    assert_equal "Missing title", last_response.body
  end

  def test_page_edit
    assert_nil @page.reload.content

    post "/#{CGI.escape(@page.slug)}", title: @page.title, content: "foo bar"

    redirect_location = last_response["Location"]
    assert_equal 302, last_response.status
    assert_equal "/#{CGI.escape(@page.slug)}", URI(redirect_location).path
    assert_equal "foo bar", @page.reload.content
  end

  def test_page_preview
    post "/#{CGI.escape(@page.slug)}/preview", title: @page.title,
                                               content: "## Foo Bar"

    assert 200, last_response.status
    assert last_response.body.include?("<h2>Foo Bar</h2>")
  end
end
