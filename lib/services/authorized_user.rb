require 'octokit'

class AuthorizedUser
  attr_reader :user_info

  def initialize(access_token)
    @client = Octokit::Client.new(access_token: access_token)
    @user_info = @client.user.to_hash
  end

  def login
    @user_info.fetch(:login)
  end

  def starkast?
    @client.organization_member?('starkast', login)
  end
end
