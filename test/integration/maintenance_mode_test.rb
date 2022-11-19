# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class MaintenanceModeTest < Minitest::Test
  include Rack::Test::Methods

  OUTER_APP = ->() { Rack::Builder.parse_file("config.ru").first }

  def app
    OUTER_APP.call
  end

  def assert_maintenance_mode
    ClimateControl.modify(MAINTENANCE_MODE: "true") do
      yield

      assert_equal 503, last_response.status
      assert_equal "Offline for maintenance", last_response.body
    end
  end

  def test_root
    assert_maintenance_mode do
      get "/"
    end
  end

  def test_root_logged_in
    assert_maintenance_mode do
      env "rack.session", { login: "not used", user_id: rand(100) }
      get "/"
    end
  end

  def test_latest
    assert_maintenance_mode do
      get "/latest"
    end
  end

  def test_list
    assert_maintenance_mode do
      get "/list"
    end
  end
end
