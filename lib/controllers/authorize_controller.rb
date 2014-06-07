require 'uri'

class AuthorizeController < BaseController
  GITHUB_OAUTH_AUTHORIZE_URL = %q(https://github.com/login/oauth/authorize)

  get '/' do
    parameters = %Q(?scope=user:email&client_id=#{ENV.fetch('GITHUB_BASIC_CLIENT_ID')})

    redirect URI.join(GITHUB_OAUTH_AUTHORIZE_URL, parameters)
  end

  get '/callback' do
    session_code = request.env.fetch('rack.request.query_hash').fetch('code')
    access_token = Authorize.access_token(session_code)
    user_info    = Authorize.user_info(access_token)
    user         = Authorize.create_or_update_user(user_info)

    session[:user_info] = user_info
    session[:login]     = user_info.fetch(:login)
    session[:user_id]   = user.id

    redirect '/'
  end

  get '/reset' do
    session.clear

    redirect back
  end
end
