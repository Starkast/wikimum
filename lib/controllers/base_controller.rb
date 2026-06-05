# frozen_string_literal: true

require 'rack-flash'
require 'rack/protection'
require 'sinatra/haml_helpers'
require 'sinatra/reloader'
require 'tilt/haml'

class BaseController < Sinatra::Base
  set :views, -> { "views/#{self.name.downcase.sub('controller', '')}" }
  set :haml, layout: :'/../layout', format: :html5, escape_html: true

  CSRF = Rack::Protection::AuthenticityToken.new(nil)

  use Rack::Flash

  helpers Sinatra::HamlHelpers

  configure :development do
    register Sinatra::Reloader
  end

  before do
    prevent_unauthorized_modifications

    # Initialize instance variables
    @q          = nil
    @page       = nil
    @page_title = nil
  end

  # Don't write a session cookie back when there's nothing to persist.
  # The layout reads `session[:login]` via `logged_in?` on every render,
  # which marks the session as "loaded" and would otherwise make rack-session
  # write a fresh Set-Cookie for every anonymous response. Set-Cookie blocks
  # nginx from caching the response, and there's nothing useful in the
  # cookie when the session hash is empty anyway.
  # Keys that rack-session and Rack::Flash put in the session even when no
  # user data exists:
  #   - "session_id": Sinatra/rack-session inserts this on first access.
  #   - "__FLASH__":  Rack::Flash seeds an empty Hash on every request.
  # Treat a session containing only these (and an empty __FLASH__) as empty.
  SESSION_NOISE_KEYS = %w[session_id __FLASH__].freeze

  def session_has_real_data?
    data = session.to_hash.reject { |k, _| SESSION_NOISE_KEYS.include?(k.to_s) }
    return true unless data.empty?
    flash = session["__FLASH__"]
    flash.is_a?(Hash) && flash.any?
  end

  before do
    # Snapshot whether the request *arrived* with a populated session so the
    # after-filter can tell anonymous-throughout (skip the cookie, lets nginx
    # cache) apart from logout-this-request (must write a fresh cookie to
    # overwrite the browser's signed login cookie — see `/authorize/reset`).
    @session_had_real_data_on_entry = session_has_real_data?
  end

  after do
    session_options = request.env["rack.session.options"]
    next unless session_options
    next if @session_had_real_data_on_entry
    next if session_has_real_data?

    session_options[:skip] = true
  end

  helpers do
    def logged_in?
      session[:login]
    end

    def current_user
      User[session.fetch(:user_id)]
    end

    def starkast?
      session[:starkast]
    end

    def csrf_token
      Rack::Protection::AuthenticityToken.token(session)
    end

    def prevent_unauthorized_modifications
      return if request.request_method == "GET"

      unless logged_in?
        flash[:error] = "Not authorized!"

        redirect back
      end

      halt 403, "Forbidden" unless CSRF.accepts?(request.env)
    end
  end
end
