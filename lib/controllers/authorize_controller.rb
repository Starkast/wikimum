# frozen_string_literal: true

require 'rack/utils'
require 'securerandom'
require 'uri'

class AuthorizeController < BaseController
  GITHUB_OAUTH_AUTHORIZE_URL = %q(https://github.com/login/oauth/authorize).freeze

  get '/' do
    halt 400, "No referrer" unless request.referrer

    session[:state] = SecureRandom.hex(32)

    # redirect_uri is already percent-encoded, so build the query by hand to avoid double-encoding.
    query = [
      "scope=user:email",
      "client_id=#{ENV.fetch('GITHUB_BASIC_CLIENT_ID')}",
      "redirect_uri=#{Authorize.construct_redirect_uri(request.referrer)}",
      "state=#{session[:state]}",
    ].join("&")

    redirect URI.join(GITHUB_OAUTH_AUTHORIZE_URL, "?#{query}")
  end

  get '/callback*' do
    query = request.env.fetch('rack.request.query_hash')

    session_code = query.fetch('code') do
      halt 404, "No code"
    end

    # Reject the callback unless it carries the state we issued (OAuth CSRF guard).
    expected_state = session.delete(:state)
    unless expected_state && Rack::Utils.secure_compare(expected_state, query['state'].to_s)
      halt 403, "Invalid state"
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

    # Clearing the session in memory isn't enough: rack-session would still
    # write a fresh signed `wikimum_session=<empty>` cookie on the way out,
    # which keeps tripping `proxy_cache_bypass $cookie_wikimum_session` in
    # nginx for every subsequent anonymous request (X-Cache-Status: BYPASS)
    # until the cookie expires a year later. Tell rack-session to skip the
    # commit and write an explicit deletion cookie instead, so the browser
    # actually drops it and post-logout requests can HIT the page cache.
    request.env["rack.session.options"][:drop] = true
    response.delete_cookie('wikimum_session', path: '/')

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
