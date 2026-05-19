# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/services/authorize'

class AuthorizeTest < Minitest::Test
  def test_access_token
    code = "fake_code"
    access_token = "fake_access_token"
    test_env = {
      GITHUB_BASIC_CLIENT_ID: "fake_github_id",
      GITHUB_BASIC_SECRET_ID: "fake_github_secret",
    }

    stub = stub_request(:post, Authorize::GITHUB_OAUTH_TOKEN_URL)
      .with(
        body: {
          client_id: "fake_github_id",
          client_secret: "fake_github_secret",
          code: code,
        },
        headers: { "Accept" => "application/json" },
      )
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { access_token: access_token }.to_json,
      )

    ClimateControl.modify(test_env) do
      assert_equal access_token, Authorize.access_token(code)
    end

    assert_requested(stub)
  end

  def test_construct_redirect_uri
    referrer = 'http://domain.example.com/foo'
    redirect_uri = 'http://domain.example.com/authorize/callback/foo'

    assert_equal redirect_uri, Authorize.construct_redirect_uri(referrer)
  end

  def test_deconstruct_redirect_uri
    redirect_uri = 'http://domain.example.com/authorize/callback/foo'
    uri = 'http://domain.example.com/foo'

    assert_equal uri, Authorize.deconstruct_redirect_uri(redirect_uri)
  end
end
