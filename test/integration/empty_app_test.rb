# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class EmptyAppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def test_root
    get "/"
    assert last_response.body.include?("Förstasidan")
    assert last_response.ok?
  end

  def test_dev_authorize
    login = "user_created_in_test"

    assert_nil User[login:]

    ClimateControl.modify(USER: login) do
      get "/authorize/dev"
    end

    redirect_location = last_response["location"]

    assert User[login:]
    assert_equal 302, last_response.status
    assert_equal "http://#{Rack::Test::DEFAULT_HOST}/", redirect_location
  end

  def test_root_logged_in
    env "rack.session", { login: "not used", user_id: rand(100) }
    get "/"
    follow_redirect!
    assert last_response.body.include?("Skapa ny sida")
    assert last_response.ok?
  end

  def test_latest
    get "/latest"
    assert last_response.ok?
  end

  def test_list
    get "/list"
    assert last_response.ok?
  end
end
