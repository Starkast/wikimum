require 'rack-flash'
require 'sinatra/reloader'
require 'haml'

class BaseController < Sinatra::Base
  set :views, -> { "views/#{self.name.downcase.sub('controller', '')}" }
  set :haml, layout: :'/../layout', format: :html5, escape_html: true

  use Rack::Flash

  configure :development do
    register Sinatra::Reloader
  end

  configure :production do
    require 'newrelic_rpm'
  end

  before do
    prevent_unauthorized_modifications
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
