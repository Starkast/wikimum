class HomeController < BaseController
  get '/' do
    @pages = Page.all
    haml :index
  end
end