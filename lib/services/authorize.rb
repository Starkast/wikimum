require 'addressable/uri'
require 'rest-client'
require 'json'

module Authorize
  module_function

  GITHUB_OAUTH_TOKEN_URL = %q(https://github.com/login/oauth/access_token)
  REDIRECT_URI_BASE_PATH = %q(/authorize/callback)

  def access_token(code)
    oauth_result = RestClient.post(GITHUB_OAUTH_TOKEN_URL,
      {
        client_id:     ENV.fetch('GITHUB_BASIC_CLIENT_ID'),
        client_secret: ENV.fetch('GITHUB_BASIC_SECRET_ID'),
        code:          code
      },
      accept: :json)

    JSON.parse(oauth_result).fetch('access_token')
  end

  def create_or_update_user(user_info)
    user = User.find_or_create(github_id: user_info.fetch(:id))
    user.login = user_info.fetch(:login)
    user.email = user_info.fetch(:email, nil)
    user.last_login = Time.now
    user.save
  end

  def construct_redirect_uri(referrer)
    uri = Addressable::URI.parse(referrer)
    File.join(uri.site, REDIRECT_URI_BASE_PATH, uri.path)
  end

  def deconstruct_redirect_uri(uri)
    uri = Addressable::URI.parse(uri)
    new_path = uri.path.sub(REDIRECT_URI_BASE_PATH, "")
    File.join(uri.site, new_path)
  end
end
