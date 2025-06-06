# frozen_string_literal: true

require 'uri'

class AuthorizeController < BaseController
  GITHUB_OAUTH_AUTHORIZE_URL = %q(https://github.com/login/oauth/authorize).freeze

  get '/' do
    halt 400, "No referrer" unless request.referrer

    redirect_uri = Authorize.construct_redirect_uri(request.referrer)
    parameters = %Q(?scope=user:email&client_id=#{ENV.fetch('GITHUB_BASIC_CLIENT_ID')}&redirect_uri=#{redirect_uri})

    redirect URI.join(GITHUB_OAUTH_AUTHORIZE_URL, parameters)
  end

  get '/callback*' do
    session_code = request.env.fetch('rack.request.query_hash').fetch('code') do
      halt 404, "No code"
    end
    access_token = Authorize.access_token(session_code)
    authed_user  = AuthorizedUser.new(access_token)
    user         = Authorize.create_or_update_user(authed_user.user_info)

    session[:user_info] = authed_user.user_info
    session[:login]     = authed_user.login
    session[:starkast]  = authed_user.starkast?
    session[:user_id]   = user.id

    redirect Authorize.deconstruct_redirect_uri(request.url)
  end

  get '/reset' do
    session.clear

    redirect back
  end

  get '/dev' do
    halt 404 unless (App.development? || App.test?)

    github_id = 1337
    login     = ENV.fetch("USER", "user_created_in_dev")
    user      = Authorize.create_or_update_user({ id: github_id, login: })

    session[:login]    = login
    session[:user_id]  = user.id
    session[:starkast] = true

    redirect "/"
  end
end
