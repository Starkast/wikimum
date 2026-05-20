# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/services/authorized_user'

class AuthorizedUserTest < Minitest::Test
  ACCESS_TOKEN = "fake_access_token"

  def stub_user(body)
    stub_request(:get, "https://api.github.com/user")
      .with(headers: { "Authorization" => "Bearer #{ACCESS_TOKEN}", "Accept" => "application/vnd.github+json" })
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: body.to_json,
      )
  end

  def stub_org_member(login, status)
    stub_request(:get, "https://api.github.com/orgs/starkast/members/#{login}")
      .with(headers: { "Authorization" => "Bearer #{ACCESS_TOKEN}" })
      .to_return(status: status)
  end

  def test_user_info_has_symbol_keys
    stub_user(id: 42, login: "octocat", email: "octocat@example.com")

    user = AuthorizedUser.new(ACCESS_TOKEN)

    assert_equal "octocat", user.user_info.fetch(:login)
    assert_equal 42, user.user_info.fetch(:id)
    assert_equal "octocat@example.com", user.user_info.fetch(:email)
  end

  def test_login_returns_user_login
    stub_user(id: 1, login: "octocat")

    assert_equal "octocat", AuthorizedUser.new(ACCESS_TOKEN).login
  end

  def test_starkast_true_when_member
    stub_user(id: 1, login: "octocat")
    stub_org_member("octocat", 204)

    assert_predicate AuthorizedUser.new(ACCESS_TOKEN), :starkast?
  end

  def test_starkast_false_when_not_member
    # GitHub returns 302 (redirect to /public_members/...) when the requester
    # is not an org member. We only treat 204 as membership, so any non-204
    # response — 302, 404, 5xx — counts as not a member.
    stub_user(id: 1, login: "octocat")
    stub_org_member("octocat", 302)

    refute_predicate AuthorizedUser.new(ACCESS_TOKEN), :starkast?
  end
end
