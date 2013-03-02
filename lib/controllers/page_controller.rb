class PageController < BaseController
  get '/' do
    @page = Page.first
    haml :show
  end

  get '/list' do
    @pages = Page.all
    haml :index
  end

  get '/new' do
    haml :new
  end

  get '/:id' do |id|
    @page = Page[id]
    haml :show
  end

  post '/new' do
    page = Page.create(title: params[:title], content: params[:content])
    redirect "#{page.pk}"
  end

  get '/:id/edit' do |id|
    @page = Page[id]
    haml :edit
  end

  # Borde vara put
  post '/:id' do |id|
    page = Page[id]
    page.update(title: params[:title], content: params[:content])

    redirect "#{page.pk}"
  end
end