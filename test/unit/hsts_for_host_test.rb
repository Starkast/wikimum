# frozen_string_literal: true

require "rack/test"

require_relative "../test_helper"
require_relative "../../lib/hsts_for_host"

class HstsForHostTest < Minitest::Test
  include Rack::Test::Methods

  INNER_APP = ->(_env) { [200, {}, ["ok"]] }

  def app
    Rack::Builder.new do
      use HstsForHost, host: "starkast.wiki"
      run INNER_APP
    end
  end

  def test_adds_hsts_header_on_matching_host
    get "/", {}, { "HTTP_HOST" => "starkast.wiki" }

    assert_equal "max-age=63072000; includeSubDomains; preload",
                 last_response.headers["strict-transport-security"]
  end

  def test_does_not_add_hsts_header_on_other_hosts
    get "/", {}, { "HTTP_HOST" => "wikimum.fly.dev" }

    assert_nil last_response.headers["strict-transport-security"]
  end
end
