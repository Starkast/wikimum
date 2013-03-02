class BaseController < Sinatra::Base
  set :views, -> { "views/#{self.name.downcase.sub('controller', '')}" }
  set :haml, layout: :'/../layout', format: :html5, escape_html: true
end