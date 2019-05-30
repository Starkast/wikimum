# frozen_string_literal: true

require_relative "../test_helper"

class EmptyAppTest < Minitest::Test
  include Rack::Test::Methods

  OUTER_APP = Rack::Builder.parse_file("config.ru").first

  def app
    OUTER_APP
  end

  def test_root
    get "/"
    assert last_response.body.include?("Förstasidan")
    assert last_response.ok?
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
