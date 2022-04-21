# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppConcealedPagesTest < Minitest::Test
  include Rack::Test::Methods

  OUTER_APP = Rack::Builder.parse_file("config.ru").first

  def app
    OUTER_APP
  end

  def setup
    user = User.create(email: "test@test")
    Page.create(title: "Concealed", author: user, concealed: true)
  end

  def teardown
    Page[title: "Concealed"].destroy
    User[email: "test@test"].destroy
  end

  def login_as_starkast
    env "rack.session", { login: "not used", user_id: rand(100), starkast: true }
  end

  def test_concealed
    get "/Concealed"
    follow_redirect!
    assert last_response.body.include?("Not authorized")
    assert last_response.ok?
  end

  def test_concealed_logged_in_as_starkast
    login_as_starkast
    get "/Concealed"
    assert last_response.ok?
  end

  def test_latest
    get "/latest"
    refute last_response.body.include?("Concealed")
    assert last_response.ok?
  end

  def test_latest_logged_in_as_starkast
    login_as_starkast
    get "/latest"
    assert last_response.body.include?("Concealed")
    assert last_response.ok?
  end

  def test_list
    get "/list"
    refute last_response.body.include?("Concealed")
    assert last_response.ok?
  end

  def test_list_logged_in_as_starkast
    login_as_starkast
    get "/list"
    assert last_response.body.include?("Concealed")
    assert last_response.ok?
  end
end
