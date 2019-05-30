# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/services/authorize'

class AuthorizeTest < Minitest::Test
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
