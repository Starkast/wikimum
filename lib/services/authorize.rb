require 'rest-client'
require 'json'

module Authorize
  module_function

  GITHUB_OAUTH_AUTHORIZE_URL = %q(https://github.com/login/oauth/authorize)
  GITHUB_OAUTH_TOKEN_URL =     %q(https://github.com/login/oauth/access_token)

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

  def user_info(access_token)
    user_response = RestClient.get('https://api.github.com/user',
      {
        params: {
          access_token: access_token
        }
      }
    )
    JSON.parse(user_response, symbolize_names: true)
  end
end
