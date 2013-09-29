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
end
