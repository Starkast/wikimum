# frozen_string_literal: true

require 'rack-flash'
require 'sinatra/reloader'
require 'tilt/haml'

class BaseController < Sinatra::Base
  set :views, -> { "views/#{self.name.downcase.sub('controller', '')}" }
  set :haml, layout: :'/../layout', format: :html5, escape_html: true
  set :logging, true
  set :js, [{
    url: "https://unpkg.com/htmx.org@1.9.9",
    sha: "sha384-QFjmbokDn2DjBjq+fM+8LUIVrAgqcNW2s0PjAxHETgRn9l4fvX31ZxDxvwQnyMOX",
  }]

  use Rack::Flash

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

    def prevent_unauthorized_modifications
      return if request.request_method == "GET"

      unless logged_in?
        flash[:error] = "Not authorized!"

        redirect back
      end
    end
  end
end
