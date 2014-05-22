require 'uri'
require 'rest-client'
require 'json'

class AuthorizeController < BaseController

  GITHUB_OAUTH_AUTHORIZE_URL = %q(https://github.com/login/oauth/authorize)
  GITHUB_OAUTH_TOKEN_URL =     %q(https://github.com/login/oauth/access_token)

  get '/' do
    parameters = %Q(?scope=user:email&client_id=#{ENV.fetch('GITHUB_BASIC_CLIENT_ID')})

    redirect URI.join(GITHUB_OAUTH_AUTHORIZE_URL, parameters)
  end

  get '/callback' do
    session_code = request.env.fetch('rack.request.query_hash').fetch('code')

    oauth_result = RestClient.post(GITHUB_OAUTH_TOKEN_URL,
                            { client_id: ENV.fetch('GITHUB_BASIC_CLIENT_ID'),
                              client_secret: ENV.fetch('GITHUB_BASIC_SECRET_ID'),
                              code: session_code},
                              accept: :json )

    access_token = JSON.parse(oauth_result).fetch('access_token')

    user_response = RestClient.get('https://api.github.com/user',
      { params: { access_token: access_token } })
    user_result = JSON.parse(user_response, symbolize_names: true)

    user_result.each do |key, value|
      session[key] = value
    end

    redirect '/'
  end

  get '/reset' do
    session.clear

    redirect back
  end
end
