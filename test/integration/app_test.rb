# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  OUTER_APP = Rack::Builder.parse_file("config.ru").first

  def app
    OUTER_APP
  end

  def setup
    user = User.create(email: "test@test")
    Page.create(title: "Test åäö", author: user)
  end

  def teardown
    Page[title: "Test åäö"].destroy
    User[email: "test@test"].destroy
  end

  def test_root
    get "/"
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
    env "rack.session", { login: "not used", user_id: rand(100) }
    get "/user"
    assert last_response.ok?
  end
end
