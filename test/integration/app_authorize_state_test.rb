# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_test_helper"

class AppAuthorizeStateTest < Minitest::Test
  include Rack::Test::Methods

  def app
    STATIC_APP
  end

  def test_callback_with_mismatched_state_is_rejected
    env "rack.session", { state: "expected" }

    get "/authorize/callback?code=abc&state=attacker"

    assert_equal 403, last_response.status
  end

  def test_callback_without_state_param_is_rejected
    env "rack.session", { state: "expected" }

    get "/authorize/callback?code=abc"

    assert_equal 403, last_response.status
  end
end
