require 'rack-flash'
require 'sinatra/reloader'

class BaseController < Sinatra::Base
  set :views, -> { "views/#{self.name.downcase.sub('controller', '')}" }
  set :haml, layout: :'/../layout', format: :html5, escape_html: true

  enable :sessions
  use Rack::Flash

  configure :development do
    register Sinatra::Reloader
  end

  before do
    prevent_unauthorized_modifications
  end

  helpers do
    def prevent_unauthorized_modifications
      return if request.request_method == "GET"

      unless session[:login]
        flash[:error] = "Not authorized!"

        redirect back
      end
    end
  end
end