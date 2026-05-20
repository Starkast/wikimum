# frozen_string_literal: true

require 'httpx'
require 'json'

class AuthorizedUser
  GITHUB_API_BASE = 'https://api.github.com'

  attr_reader :user_info

  def initialize(access_token)
    @http = HTTPX.with(
      timeout: { connect_timeout: 5, request_timeout: 10 },
      headers: {
        "Authorization" => "Bearer #{access_token}",
        "Accept" => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2022-11-28",
      },
    )
    response = @http.get("#{GITHUB_API_BASE}/user")
    response.raise_for_status
    @user_info = JSON.parse(response.to_s, symbolize_names: true)
  end

  def login
    @user_info.fetch(:login)
  end

  def starkast?
    response = @http.get("#{GITHUB_API_BASE}/orgs/starkast/members/#{login}")
    response.status == 204
  end
end
